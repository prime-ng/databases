# Prime-AI Platform — Menu-Aligned Requirements Breakdown Structure (RBS)

> **AI-Powered School ERP + LMS + LXP Multi-Tenant SaaS Platform**  
> This document maps every screen/tab in the Prime-AI navigation to its
> module code, sub-module, functionality, tasks, and atomic sub-tasks.
> Use this as the authoritative reference for development planning, API design,
> database schema generation, and sprint task breakdown.

---

## Document Structure

| Section | Contents |
|---------|----------|
| [Part 1 — Prime App RBS](#part-1--prime-app-rbs) | SaaS/PG admin: tenant mgmt., billing, subscriptions |
| [Part 2 — Tenant App RBS](#part-2--tenant-app-rbs) | School-facing: academics, fees, HR, transport, LMS, LXP, AI |
| [Part 3 — Full RBS Module Index](#part-3--full-rbs-module-index) | All 27 modules with sub-module task counts |

### Reading Guide

Each screen entry follows this hierarchy:

```
## Category
### Main Menu
#### Sub-Menu  (if applicable)
##### Tab / Screen  [Table: xxx | DB: yyy]
**Mod·Sub-Mod** | Functionality > Task
- ST.X.Y.Z  Sub-task description
```

---

---

# Part 1 — Prime App RBS

> **Audience:** Super-admins, SaaS operators, platform engineers  
> **Scope:** Tenant onboarding, subscription & billing, platform configuration


## PG - Foudational Setup
---

### Menu Mgmt.

##### Menu Management (Single Screen)
> CRUD for Category, Main Menu & Sub-Menu Items
> Table: `glb_menus` | *global_db*

  **F.A2.1 — Feature Toggles**
  - *T.A2.1.1 — Enable/Disable Modules*
    - `ST.A2.1.1.1` Turn ON/OFF module access
    - `ST.A2.1.1.2` Auto-update user access
  - *T.A2.1.2 — Advanced Feature Flags*
    - `ST.A2.1.2.1` Enable premium analytics
    - `ST.A2.1.2.2` Enable AI-based recommendations


### System Config

#### System Settings

##### System Settings (Single Screen)
> CRUD for System Settings
> Table: `sys_settings` | *prime_db*

  **F.A1.1 — Tenant Creation**
  - *T.A1.1.1 — Create Tenant*
    - `ST.A1.1.1.1` Enter school/organization name
    - `ST.A1.1.1.2` Assign tenant code
    - `ST.A1.1.1.3` Capture contact & address details
    - `ST.A1.1.1.4` Upload logo and branding
  - *T.A1.1.2 — Configure Default Settings*
    - `ST.A1.1.2.1` Set academic year
    - `ST.A1.1.2.2` Select default country/state/timezone
  **F.A1.2 — Subscription Assignment**
  - *T.A1.2.1 — Choose Plan*
    - `ST.A1.2.1.1` Select subscription plan
    - `ST.A1.2.1.2` Attach modules enabled in plan
  - *T.A1.2.2 — Billing Cycle Setup*
    - `ST.A1.2.2.1` Define billing cycle (Monthly/Yearly)
    - `ST.A1.2.2.2` Set next billing date


#### Dropdown Requirement

##### Dropdown Menu Requirement
> Crud for Dropdown Requirement
> Table: `sys_dropdown_needs` | *prime_db*

  **F.A1.1 — Tenant Creation**
  - *T.A1.1.1 — Create Tenant*
  - *T.A1.1.2 — Configure Default Settings*
  **F.A1.2 — Subscription Assignment**
  - *T.A1.2.1 — Choose Plan*
  - *T.A1.2.2 — Billing Cycle Setup*


#### Dropdown Menu Items

##### Dropdown Menu (Single Screen)
> Crud for Dropdown Items
> Table: `sys_dropdown_table` | *prime_db*

  **F.A1.1 — Tenant Creation**
  - *T.A1.1.1 — Create Tenant*
  - *T.A1.1.2 — Configure Default Settings*
  **F.A1.2 — Subscription Assignment**
  - *T.A1.2.1 — Choose Plan*
  - *T.A1.2.2 — Billing Cycle Setup*


#### Media Store

##### Media Store (Single Screen)
> CRUD for System Media (Mainly for View but can be Modified)
> Table: `sys_media` | *prime_db*

  **F.A1.1 — Tenant Creation**
  - *T.A1.1.1 — Create Tenant*
  - *T.A1.1.2 — Configure Default Settings*
  **F.A1.2 — Subscription Assignment**
  - *T.A1.2.1 — Choose Plan*
  - *T.A1.2.2 — Billing Cycle Setup*


#### Vew Activities

##### View Activities (Single Screen)
> View with Filter for Activities
> Table: `sys_activity_logs` | *prime_db*

  **F.A6.1 — System Logs**
  - *T.A6.1.1 — Track Activities*
    - `ST.A6.1.1.1` Log user login/logout
    - `ST.A6.1.1.2` Log data changes
  - *T.A6.1.2 — Export Logs*
    - `ST.A6.1.2.1` Download audit logs CSV
    - `ST.A6.1.2.2` Filter logs by user/date


### Language Mgmt.

##### Language Setup
> This Tab will provide Operations (CRUD)
> Table: `glb_languages` | *prime_db*

  **F.A1.1 — Tenant Creation**
  - *T.A1.1.1 — Create Tenant*
  - *T.A1.1.2 — Configure Default Settings*
  **F.A1.2 — Subscription Assignment**
  - *T.A1.2.1 — Choose Plan*
  - *T.A1.2.2 — Billing Cycle Setup*


##### Menu Translation
> This will accommodate translation of Menu Items and other Items.
> Table: `glb_translations` | *prime_db*

  **F.A1.1 — Tenant Creation**
  - *T.A1.1.1 — Create Tenant*
  - *T.A1.1.2 — Configure Default Settings*
  **F.A1.2 — Subscription Assignment**
  - *T.A1.2.1 — Choose Plan*
  - *T.A1.2.2 — Billing Cycle Setup*


### Location Mgmt

##### Country
> CRUD for Country
> Table: `glb_countries` | *global_db*

  **F.A1.1 — Tenant Creation**
  - *T.A1.1.1 — Create Tenant*
  - *T.A1.1.2 — Configure Default Settings*
  **F.A1.2 — Subscription Assignment**
  - *T.A1.2.1 — Choose Plan*
  - *T.A1.2.2 — Billing Cycle Setup*


##### State
> CRUD for State
> Table: `glb_states` | *global_db*

  **F.A1.1 — Tenant Creation**
  - *T.A1.1.1 — Create Tenant*
  - *T.A1.1.2 — Configure Default Settings*
  **F.A1.2 — Subscription Assignment**
  - *T.A1.2.1 — Choose Plan*
  - *T.A1.2.2 — Billing Cycle Setup*


##### District
> CRUD for District
> Table: `glb_districts` | *global_db*

  **F.A1.1 — Tenant Creation**
  - *T.A1.1.1 — Create Tenant*
  - *T.A1.1.2 — Configure Default Settings*
  **F.A1.2 — Subscription Assignment**
  - *T.A1.2.1 — Choose Plan*
  - *T.A1.2.2 — Billing Cycle Setup*


##### City
> CRUD for City
> Table: `glb_cities` | *global_db*

  **F.A1.1 — Tenant Creation**
  - *T.A1.1.1 — Create Tenant*
  - *T.A1.1.2 — Configure Default Settings*
  **F.A1.2 — Subscription Assignment**
  - *T.A1.2.1 — Choose Plan*
  - *T.A1.2.2 — Billing Cycle Setup*


## PG - Core Configuration
---

### Roles & Permission (Prime)

##### Roles
> CRUD for Roles
> Table: `sys_permissions` | *prime_db*

  **F.B2.1 — Role Creation**
  - *T.B2.1.1 — Create Role*
    - `ST.B2.1.1.1` Define role name
    - `ST.B2.1.1.2` Add description
    - `ST.B2.1.1.3` Select applicable modules
  - *T.B2.1.2 — Clone Role*
    - `ST.B2.1.2.1` Choose existing role
    - `ST.B2.1.2.2` Duplicate permissions
    - `ST.B2.1.2.3` Modify cloned role
  **F.B2.2 — Role Assignment**
  - *T.B2.2.1 — Assign Role to User*
    - `ST.B2.2.1.1` Select user
    - `ST.B2.2.1.2` Select one or multiple roles
    - `ST.B2.2.1.3` Apply assignment


##### Permission Mgmt.
> Assign Permission to Roles
> Table: `sys_roles` | *prime_db*

  **F.B3.1 — Module Permissions**
  - *T.B3.1.1 — Grant Module Access*
    - `ST.B3.1.1.1` Enable module visibility
    - `ST.B3.1.1.2` Grant create/read/update/delete rights
  - *T.B3.1.2 — Restrict Functionality*
    - `ST.B3.1.2.1` Disable sensitive features
    - `ST.B3.1.2.2` Restrict student/fee access
  **F.B3.2 — Page-Level Permissions**
  - *T.B3.2.1 — Fine-Grained Control*
    - `ST.B3.2.1.1` Enable page access
    - `ST.B3.2.1.2` Disable page elements
  - *T.B3.2.2 — UI Element-Level Permissions*
    - `ST.B3.2.2.1` Control button visibility
    - `ST.B3.2.2.2` Restrict action triggers


##### User
> CRUD for User and Assign Roles
> Table: `sys_users` | *prime_db*

  **F.B1.1 — User Creation**
  - *T.B1.1.1 — Create User Profile*
    - `ST.B1.1.1.1` Enter user details (name, email, phone)
    - `ST.B1.1.1.2` Assign default role
    - `ST.B1.1.1.3` Send activation email
  - *T.B1.1.2 — Bulk User Upload*
    - `ST.B1.1.2.1` Upload CSV of users
    - `ST.B1.1.2.2` Map CSV columns to fields
    - `ST.B1.1.2.3` Validate and import users
  **F.B1.2 — User Profile Editing**
  - *T.B1.2.1 — Edit User Details*
    - `ST.B1.2.1.1` Modify contact information
    - `ST.B1.2.1.2` Update profile photo
    - `ST.B1.2.1.3` Edit personal information
  - *T.B1.2.2 — User Status Management*
    - `ST.B1.2.2.1` Activate user
    - `ST.B1.2.2.2` Deactivate user
    - `ST.B1.2.2.3` Lock/Unlock account


### Session & Board Setup

##### Academic Session
> CRUD for Academic Sessions
> Table: `glb_academic_sessions` | *global_db*

  **F.A1.1 — Tenant Creation**
  - *T.A1.1.1 — Create Tenant*
  - *T.A1.1.2 — Configure Default Settings*
  **F.A1.2 — Subscription Assignment**
  - *T.A1.2.1 — Choose Plan*
  - *T.A1.2.2 — Billing Cycle Setup*


##### Academic Board
> CRUD for Academic Boards
> Table: `glb_boards` | *global_db*

  **F.A1.1 — Tenant Creation**
  - *T.A1.1.1 — Create Tenant*
  - *T.A1.1.2 — Configure Default Settings*
  **F.A1.2 — Subscription Assignment**
  - *T.A1.2.1 — Choose Plan*
  - *T.A1.2.2 — Billing Cycle Setup*


### Sales Plan & Module Mgmt.

##### Billing Cycle
> CRUD for Billing Cycle
> Table: `prm_billing_cycle` | *prime_db*

  **F.V1.1 — Plan Configuration**
  - *T.V1.1.1 — Create Subscription Plan*
    - `ST.V1.1.1.1` Define plan name & description
    - `ST.V1.1.1.2` Set pricing (monthly/quarterly/yearly)
    - `ST.V1.1.1.3` Assign included modules/features
  - *T.V1.1.2 — Plan Rules*
    - `ST.V1.1.2.1` Define user limits
    - `ST.V1.1.2.2` Set storage limits
    - `ST.V1.1.2.3` Configure overage pricing
  **F.V1.2 — Plan Management**
  - *T.V1.2.1 — Edit/Update Plan*
    - `ST.V1.2.1.1` Modify pricing & limits
    - `ST.V1.2.1.2` Update feature list
  - *T.V1.2.2 — Plan Activation/Deactivation*
    - `ST.V1.2.2.1` Activate plan for sale
    - `ST.V1.2.2.2` Retire old plan versions


##### Modules
> CRUD for Modules
> Table: `glb_modules` | *global_db*

  **F.V1.1 — Plan Configuration**
  - *T.V1.1.1 — Create Subscription Plan*
  - *T.V1.1.2 — Plan Rules*
  **F.V1.2 — Plan Management**
  - *T.V1.2.1 — Edit/Update Plan*
  - *T.V1.2.2 — Plan Activation/Deactivation*


##### Allign Menu with Module
> Connect Menu Items with Modules
> Table: `glb_menu_module_jnt` | *global_db*

  **F.V1.1 — Plan Configuration**
  - *T.V1.1.1 — Create Subscription Plan*
  - *T.V1.1.2 — Plan Rules*
  **F.V1.2 — Plan Management**
  - *T.V1.2.1 — Edit/Update Plan*
  - *T.V1.2.2 — Plan Activation/Deactivation*


##### Plans
> CRUD for Plans
> Table: `prm_plans` | *prime_db*

  **F.V1.1 — Plan Configuration**
  - *T.V1.1.1 — Create Subscription Plan*
  - *T.V1.1.2 — Plan Rules*
  **F.V1.2 — Plan Management**
  - *T.V1.2.1 — Edit/Update Plan*
  - *T.V1.2.2 — Plan Activation/Deactivation*


##### Assign Module to Plan
> Connect Modules with Plans
> Table: `prm_module_plan_jnt` | *prime_db*

  **F.V1.1 — Plan Configuration**
  - *T.V1.1.1 — Create Subscription Plan*
  - *T.V1.1.2 — Plan Rules*
  **F.V1.2 — Plan Management**
  - *T.V1.2.1 — Edit/Update Plan*
  - *T.V1.2.2 — Plan Activation/Deactivation*


## PG - Subscription & Billing
---

### Tenant & Subscription Mgmt.

##### Tenant Group
> CRUD for Tenant Group
> Table: `prm_tenant_groups` | *prime_db*

  **F.V2.1 — Subscription Purchase**
  - *T.V2.1.1 — Assign Plan to Tenant*
    - `ST.V2.1.1.1` Select subscription plan
    - `ST.V2.1.1.2` Set start/end date
    - `ST.V2.1.1.3` Configure billing cycle
  - *T.V2.1.2 — Trial Management*
    - `ST.V2.1.2.1` Enable trial period
    - `ST.V2.1.2.2` Auto‑convert trial to paid subscription
  **F.V2.2 — Subscription Lifecycle**
  - *T.V2.2.1 — Renewal Management*
    - `ST.V2.2.1.1` Auto‑renew subscription
    - `ST.V2.2.1.2` Notify tenant for manual renewal
  - *T.V2.2.2 — Upgrade/Downgrade*
    - `ST.V2.2.2.1` Switch plan mid‑cycle
    - `ST.V2.2.2.2` Apply prorated charges


##### Tenant Creation
> CRUD for Tenant
> Table: `prm_tenant` | *prime_db*

  **F.A1.1 — Tenant Creation**
  - *T.A1.1.1 — Create Tenant*
  - *T.A1.1.2 — Configure Default Settings*
  **F.A1.2 — Subscription Assignment**
  - *T.A1.2.1 — Choose Plan*
  - *T.A1.2.2 — Billing Cycle Setup*
  **F.V2.1 — Subscription Purchase**
  - *T.V2.1.1 — Assign Plan to Tenant*
  - *T.V2.1.2 — Trial Management*
  **F.V2.2 — Subscription Lifecycle**
  - *T.V2.2.1 — Renewal Management*
  - *T.V2.2.2 — Upgrade/Downgrade*


##### DB & Domain
> CRUD for DB & Domain Detail
> Table: `prm_tenant_domains` | *prime_db*

  **F.V2.1 — Subscription Purchase**
  - *T.V2.1.1 — Assign Plan to Tenant*
  - *T.V2.1.2 — Trial Management*
  **F.V2.2 — Subscription Lifecycle**
  - *T.V2.2.1 — Renewal Management*
  - *T.V2.2.2 — Upgrade/Downgrade*


##### Plan Susbscription
> CRUD for Plan Susbscription
> Table: `prm_tenant_plan_jnt` | *prime_db*

  **F.V2.1 — Subscription Purchase**
  - *T.V2.1.1 — Assign Plan to Tenant*
  - *T.V2.1.2 — Trial Management*
  **F.V2.2 — Subscription Lifecycle**
  - *T.V2.2.1 — Renewal Management*
  - *T.V2.2.2 — Upgrade/Downgrade*


##### Plan Rate
> CRUD for Plan Rate
> Table: `prm_tenant_plan_rates` | *prime_db*

  **F.V2.1 — Subscription Purchase**
  - *T.V2.1.1 — Assign Plan to Tenant*
  - *T.V2.1.2 — Trial Management*
  **F.V2.2 — Subscription Lifecycle**
  - *T.V2.2.1 — Renewal Management*
  - *T.V2.2.2 — Upgrade/Downgrade*


##### Module in Plan
> CRUD for Plan Modules
> Table: `prm_tenant_plan_module_jnt` | *prime_db*

  **F.V2.1 — Subscription Purchase**
  - *T.V2.1.1 — Assign Plan to Tenant*
  - *T.V2.1.2 — Trial Management*
  **F.V2.2 — Subscription Lifecycle**
  - *T.V2.2.1 — Renewal Management*
  - *T.V2.2.2 — Upgrade/Downgrade*


##### Billing Schedule
> CRUD for Billing Schedule
> Table: `tenant_plan_billing_schedules` | *prime_db*

  **F.V3.1 — Invoice Generation**
  - *T.V3.1.1 — Generate Invoice*
    - `ST.V3.1.1.1` Create recurring invoice
    - `ST.V3.1.1.2` Include addons/overage usage
    - `ST.V3.1.1.3` Apply taxes as per region
  - *T.V3.1.2 — Invoice Scheduling*
    - `ST.V3.1.2.1` Schedule monthly/annual billing
    - `ST.V3.1.2.2` Send reminders for unpaid invoices
  **F.V3.2 — Payment Processing**
  - *T.V3.2.1 — Record Payment*
    - `ST.V3.2.1.1` Accept online payment (UPI/Card)
    - `ST.V3.2.1.2` Record offline payment (NEFT/Cash)
  - *T.V3.2.2 — Auto‑Reconciliation*
    - `ST.V3.2.2.1` Match payment with invoice automatically
    - `ST.V3.2.2.2` Flag mismatched transactions


### Invocing

##### Invoicing
> Invoice Generation
> Table: `bil_tenant_invoices` | *prime_db*

  **F.V3.1 — Invoice Generation**
  - *T.V3.1.1 — Generate Invoice*
  - *T.V3.1.2 — Invoice Scheduling*
  **F.V3.2 — Payment Processing**
  - *T.V3.2.1 — Record Payment*
  - *T.V3.2.2 — Auto‑Reconciliation*


##### Susbcription
> Vew Susscription Detail of tenants

  **F.V2.1 — Subscription Purchase**
  - *T.V2.1.1 — Assign Plan to Tenant*
  - *T.V2.1.2 — Trial Management*
  **F.V2.2 — Subscription Lifecycle**
  - *T.V2.2.1 — Renewal Management*
  - *T.V2.2.2 — Upgrade/Downgrade*


##### Invoice Payment
> Payment Receiving (Invoice Wise)
> Table: `bil_tenant_invoicing_payments` | *prime_db*

  **F.V3.1 — Invoice Generation**
  - *T.V3.1.1 — Generate Invoice*
  - *T.V3.1.2 — Invoice Scheduling*
  **F.V3.2 — Payment Processing**
  - *T.V3.2.1 — Record Payment*
  - *T.V3.2.2 — Auto‑Reconciliation*


##### Consolidated Payment
> Payment Receiving (Consolidated)

  **F.V3.1 — Invoice Generation**
  - *T.V3.1.1 — Generate Invoice*
  - *T.V3.1.2 — Invoice Scheduling*
  **F.V3.2 — Payment Processing**
  - *T.V3.2.1 — Record Payment*
  - *T.V3.2.2 — Auto‑Reconciliation*


##### Payment Reconcilation
> Payment Reconcilation

  **F.V3.1 — Invoice Generation**
  - *T.V3.1.1 — Generate Invoice*
  - *T.V3.1.2 — Invoice Scheduling*
  **F.V3.2 — Payment Processing**
  - *T.V3.2.1 — Record Payment*
  - *T.V3.2.2 — Auto‑Reconciliation*


##### Invoice Audit
> View Auit Log and can register Notes in Audit Log
> Table: `bil_tenant_invoicing_audit_logs` | *prime_db*

  **F.V7.1 — Audit Logs**
  - *T.V7.1.1 — Track Billing Events*
    - `ST.V7.1.1.1` Record invoice creation
    - `ST.V7.1.1.2` Log payment confirmations
  - *T.V7.1.2 — Track Subscription Updates*
    - `ST.V7.1.2.1` Record plan upgrade/downgrade
    - `ST.V7.1.2.2` Maintain full audit trail
  **F.V7.2 — Compliance Reports**
  - *T.V7.2.1 — Generate Compliance Report*
    - `ST.V7.2.1.1` GST/Tax reports
    - `ST.V7.2.1.2` Country‑wise billing summaries


##### Schedule Email
> Notification Email will be schedule to sent to Tenant
> Table: `bil_tenant_email_schedules` | *prime_db*

  **F.Q1.1 — Email Sending**
  - *T.Q1.1.1 — Compose Email*
    - `ST.Q1.1.1.1` Select recipients (students/parents/staff)
    - `ST.Q1.1.1.2` Add subject, body & attachments
  - *T.Q1.1.2 — Email Scheduling*
    - `ST.Q1.1.2.1` Schedule email for later
    - `ST.Q1.1.2.2` Set recurring email rules
  **F.Q1.2 — Template Management**
  - *T.Q1.2.1 — Create Email Template*
    - `ST.Q1.2.1.1` Define template name
    - `ST.Q1.2.1.2` Add placeholders for merge fields
  - *T.Q1.2.2 — Manage Templates*
    - `ST.Q1.2.2.1` Edit template content
    - `ST.Q1.2.2.2` Activate/Deactivate template


---

# Part 2 — Tenant App RBS

> **Audience:** School admin, teachers, staff, students, parents  
> **Scope:** All school operations — academics, fees, HR, transport, hostel, LMS, LXP, AI


## FOUNDATIONAL SETUP
---

### System Configuration

#### System Settings

##### N / A
> CRUD for System Settings
> Table: `sys_settings` | *tenant_db*

  > ★ *Tasks to be defined — no RBS mapping yet.*


#### Dropdown Requirement

##### N / A
> Crud for Dropdown Requirement
> Table: `sys_dropdown_needs` | *tenant_db*

  > ★ *Tasks to be defined — no RBS mapping yet.*


#### Dropdown Menu Items

##### N / A
> Crud for Dropdown Items
> Table: `sys_dropdown_table` | *tenant_db*

  > ★ *Tasks to be defined — no RBS mapping yet.*


#### Media Store

##### N / A
> CRUD for System Media (Mainly for View but can be Modified)
> Table: `sys_media`

  > ★ *Tasks to be defined — no RBS mapping yet.*


### Roles & Permission

##### Roles
> CRUD for Roles
> Table: `sys_permissions` | *tenant_db*

  **F.B2.1 — Role Creation**
  - *T.B2.1.1 — Create Role*
    - `ST.B2.1.1.1` Define role name
    - `ST.B2.1.1.2` Add description
    - `ST.B2.1.1.3` Select applicable modules
  - *T.B2.1.2 — Clone Role*
    - `ST.B2.1.2.1` Choose existing role
    - `ST.B2.1.2.2` Duplicate permissions
    - `ST.B2.1.2.3` Modify cloned role
  **F.B2.2 — Role Assignment**
  - *T.B2.2.1 — Assign Role to User*
    - `ST.B2.2.1.1` Select user
    - `ST.B2.2.1.2` Select one or multiple roles
    - `ST.B2.2.1.3` Apply assignment


##### Permission Mgmt.
> Assign Permission to Roles
> Table: `sys_roles` | *tenant_db*

  **F.B3.1 — Module Permissions**
  - *T.B3.1.1 — Grant Module Access*
    - `ST.B3.1.1.1` Enable module visibility
    - `ST.B3.1.1.2` Grant create/read/update/delete rights
  - *T.B3.1.2 — Restrict Functionality*
    - `ST.B3.1.2.1` Disable sensitive features
    - `ST.B3.1.2.2` Restrict student/fee access
  **F.B3.2 — Page-Level Permissions**
  - *T.B3.2.1 — Fine-Grained Control*
    - `ST.B3.2.1.1` Enable page access
    - `ST.B3.2.1.2` Disable page elements
  - *T.B3.2.2 — UI Element-Level Permissions*
    - `ST.B3.2.2.1` Control button visibility
    - `ST.B3.2.2.2` Restrict action triggers


### Session & Board Setup

##### Academic Session Mgmt.
> Create New Academic Sessions
> Table: `sch_org_academic_sessions_jnt` | *tenant_db*

  **F.A1.1 — Tenant Creation**
  - *T.A1.1.1 — Create Tenant*
    - `ST.A1.1.1.1` Enter school/organization name
    - `ST.A1.1.1.2` Assign tenant code
    - `ST.A1.1.1.3` Capture contact & address details
    - `ST.A1.1.1.4` Upload logo and branding
  - *T.A1.1.2 — Configure Default Settings*
    - `ST.A1.1.2.1` Set academic year
    - `ST.A1.1.2.2` Select default country/state/timezone
  **F.A1.2 — Subscription Assignment**
  - *T.A1.2.1 — Choose Plan*
    - `ST.A1.2.1.1` Select subscription plan
    - `ST.A1.2.1.2` Attach modules enabled in plan
  - *T.A1.2.2 — Billing Cycle Setup*
    - `ST.A1.2.2.1` Define billing cycle (Monthly/Yearly)
    - `ST.A1.2.2.2` Set next billing date


##### Academic Board Mgmt.
> Adding new Academic Boards
> Table: `sch_board_organization_jnt` | *tenant_db*

  **F.A1.1 — Tenant Creation**
  - *T.A1.1.1 — Create Tenant*
  - *T.A1.1.2 — Configure Default Settings*
  **F.A1.2 — Subscription Assignment**
  - *T.A1.2.1 — Choose Plan*
  - *T.A1.2.2 — Billing Cycle Setup*


### Infra. Setup

##### Room Type
> CRUD for Room Type
> Table: `sch_rooms_type` | *tenant_db*

  **F.A1.1 — Tenant Creation**
  - *T.A1.1.1 — Create Tenant*
  - *T.A1.1.2 — Configure Default Settings*
  **F.A1.2 — Subscription Assignment**
  - *T.A1.2.1 — Choose Plan*
  - *T.A1.2.2 — Billing Cycle Setup*


##### Building
> CRUD for Building
> Table: `sch_buildings` | *tenant_db*

  **F.A1.1 — Tenant Creation**
  - *T.A1.1.1 — Create Tenant*
  - *T.A1.1.2 — Configure Default Settings*
  **F.A1.2 — Subscription Assignment**
  - *T.A1.2.1 — Choose Plan*
  - *T.A1.2.2 — Billing Cycle Setup*


##### Room
> CRUD for Rooms
> Table: `sch_rooms` | *tenant_db*

  **F.A1.1 — Tenant Creation**
  - *T.A1.1.1 — Create Tenant*
  - *T.A1.1.2 — Configure Default Settings*
  **F.A1.2 — Subscription Assignment**
  - *T.A1.2.1 — Choose Plan*
  - *T.A1.2.2 — Billing Cycle Setup*


## SCHOOL SETUP
---

### Core Config

#### Dept / Designation Mgmt.

##### Department
> Table: `sch_department` | *tenant_db*

  **F.P1.1 — Staff Profile**
  - *T.P1.1.1 — Create Staff Profile*
    - `ST.P1.1.1.1` Enter personal details
    - `ST.P1.1.1.2` Upload documents (ID, certificates)
    - `ST.P1.1.1.3` Assign employee code
  - *T.P1.1.2 — Edit Staff Profile*
    - `ST.P1.1.2.1` Update contact details
    - `ST.P1.1.2.2` Manage emergency contacts
  **F.P1.2 — Job & Employment Details**
  - *T.P1.2.1 — Set Employment Details*
    - `ST.P1.2.1.1` Define designation & department
    - `ST.P1.2.1.2` Set joining date & contract type
  - *T.P1.2.2 — Document Management*
    - `ST.P1.2.2.1` Upload appointment letter
    - `ST.P1.2.2.2` Track document renewal dates


##### Designation
> Table: `sch_designation` | *tenant_db*

  **F.P1.1 — Staff Profile**
  - *T.P1.1.1 — Create Staff Profile*
  - *T.P1.1.2 — Edit Staff Profile*
  **F.P1.2 — Job & Employment Details**
  - *T.P1.2.1 — Set Employment Details*
  - *T.P1.2.2 — Document Management*


#### User Mgmt.

##### Leave Config
> CRUD for Leave Config (Available Leave Types / Role)

  **F.P2.1 — Leave Management**
  - *T.P2.1.1 — Apply Leave*
    - `ST.P2.1.1.1` Select leave type
    - `ST.P2.1.1.2` Submit leave request
    - `ST.P2.1.1.3` Attach supporting document
  - *T.P2.1.2 — Leave Approval*
    - `ST.P2.1.2.1` Approve/Reject leave
    - `ST.P2.1.2.2` Record remarks with history
  **F.P2.2 — Attendance Integration**
  - *T.P2.2.1 — Sync Biometric Attendance*
    - `ST.P2.2.1.1` Fetch logs from biometric device
    - `ST.P2.2.1.2` Auto-mark attendance


#### Entity Group

##### Entity Group
> Table: `sch_entity_groups` | *tenant_db*

  **F.A4.1 — User Profiles**
  - *T.A4.1.1 — Create User*
    - `ST.A4.1.1.1` Enter user details
    - `ST.A4.1.1.2` Assign role
    - `ST.A4.1.1.3` Send invite email
  - *T.A4.1.2 — Edit User*
    - `ST.A4.1.2.1` Modify profile details
    - `ST.A4.1.2.2` Update contact information
  **F.A4.2 — User Deactivation**
  - *T.A4.2.1 — Disable User*
    - `ST.A4.2.1.1` Deactivate login access
    - `ST.A4.2.1.2` Retain historical data


##### Entity Group Member
> Table: `sch_entity_groups_members` | *tenant_db*

  **F.A4.1 — User Profiles**
  - *T.A4.1.1 — Create User*
  - *T.A4.1.2 — Edit User*
  **F.A4.2 — User Deactivation**
  - *T.A4.2.1 — Disable User*


#### Classification Mgmt.

##### Student Categories
> Student Categories
> Table: *tenant_db*

  **F.C4.1 — Student Profile**
  - *T.C4.1.1 — Create Student Profile*
    - `ST.C4.1.1.1` Store personal details
    - `ST.C4.1.1.2` Store address & emergency contacts
  - *T.C4.1.2 — Maintain Records*
    - `ST.C4.1.2.1` Track caste/category
    - `ST.C4.1.2.2` Update health information
  **F.C4.2 — Student Documents**
  - *T.C4.2.1 — Upload Documents*
    - `ST.C4.2.1.1` Upload TC/Marksheets
    - `ST.C4.2.1.2` Upload medical certificate
  - *T.C4.2.2 — Document Verification*
    - `ST.C4.2.2.1` Approve authenticity
    - `ST.C4.2.2.2` Update verification status


##### Student House
> Student House
> Table: *tenant_db*

  **F.C4.1 — Student Profile**
  - *T.C4.1.1 — Create Student Profile*
  - *T.C4.1.2 — Maintain Records*
  **F.C4.2 — Student Documents**
  - *T.C4.2.1 — Upload Documents*
  - *T.C4.2.2 — Document Verification*


##### Student Categories
> Disable Reason
> Table: *tenant_db*

  **F.C4.1 — Student Profile**
  - *T.C4.1.1 — Create Student Profile*
  - *T.C4.1.2 — Maintain Records*
  **F.C4.2 — Student Documents**
  - *T.C4.2.1 — Upload Documents*
  - *T.C4.2.2 — Document Verification*


##### Disable Reason

  **F.C4.1 — Student Profile**
  - *T.C4.1.1 — Create Student Profile*
  - *T.C4.1.2 — Maintain Records*
  **F.C4.2 — Student Documents**
  - *T.C4.2.1 — Upload Documents*
  - *T.C4.2.2 — Document Verification*


### Staff & Student Creation

#### Staff Mgmt.

##### User
> CRUD for User and Assign Roles
> Table: `sys_users` | *tenant_db*

  **F.B1.1 — User Creation**
  - *T.B1.1.1 — Create User Profile*
    - `ST.B1.1.1.1` Enter user details (name, email, phone)
    - `ST.B1.1.1.2` Assign default role
    - `ST.B1.1.1.3` Send activation email
  - *T.B1.1.2 — Bulk User Upload*
    - `ST.B1.1.2.1` Upload CSV of users
    - `ST.B1.1.2.2` Map CSV columns to fields
    - `ST.B1.1.2.3` Validate and import users
  **F.B1.2 — User Profile Editing**
  - *T.B1.2.1 — Edit User Details*
    - `ST.B1.2.1.1` Modify contact information
    - `ST.B1.2.1.2` Update profile photo
    - `ST.B1.2.1.3` Edit personal information
  - *T.B1.2.2 — User Status Management*
    - `ST.B1.2.2.1` Activate user
    - `ST.B1.2.2.2` Deactivate user
    - `ST.B1.2.2.3` Lock/Unlock account


##### Staff Detail
> Table: `sch_teachers` | *tenant_db*

  **F.P1.1 — Staff Profile**
  - *T.P1.1.1 — Create Staff Profile*
  - *T.P1.1.2 — Edit Staff Profile*
  **F.P1.2 — Job & Employment Details**
  - *T.P1.2.1 — Set Employment Details*
  - *T.P1.2.2 — Document Management*


##### Staff Profile
> Table: `sch_teachers_profile` | *tenant_db*

  **F.P1.1 — Staff Profile**
  - *T.P1.1.1 — Create Staff Profile*
  - *T.P1.1.2 — Edit Staff Profile*
  **F.P1.2 — Job & Employment Details**
  - *T.P1.2.1 — Set Employment Details*
  - *T.P1.2.2 — Document Management*


#### Student Admission

##### Student Detail
> Table: `std_students` | *tenant_db*

  **F.C4.1 — Student Profile**
  - *T.C4.1.1 — Create Student Profile*
  - *T.C4.1.2 — Maintain Records*
  **F.C4.2 — Student Documents**
  - *T.C4.2.1 — Upload Documents*
  - *T.C4.2.2 — Document Verification*


##### Student Personal Details
> Table: `std_student_personal_details` | *tenant_db*

  **F.C4.1 — Student Profile**
  - *T.C4.1.1 — Create Student Profile*
  - *T.C4.1.2 — Maintain Records*
  **F.C4.2 — Student Documents**
  - *T.C4.2.1 — Upload Documents*
  - *T.C4.2.2 — Document Verification*


##### Student Session Detail
> Table: `std_student_sessions_jnt` | *tenant_db*

  **F.C4.1 — Student Profile**
  - *T.C4.1.1 — Create Student Profile*
  - *T.C4.1.2 — Maintain Records*
  **F.C4.2 — Student Documents**
  - *T.C4.2.1 — Upload Documents*
  - *T.C4.2.2 — Document Verification*


## ACEDEMIC SETUP
---

### Class & Subject Setup

#### Class Mgmt.

##### Class
> Table: `sch_classes` | *tenant_db*

  **F.H1.1 — Academic Session**
  - *T.H1.1.1 — Create Session*
    - `ST.H1.1.1.1` Define academic session name
    - `ST.H1.1.1.2` Set session start & end dates
  - *T.H1.1.2 — Activate/Deactivate Session*
    - `ST.H1.1.2.1` Mark session as active
    - `ST.H1.1.2.2` Prevent edits to closed session
  **F.H1.2 — Curriculum Mapping**
  - *T.H1.2.1 — Assign Subjects to Class*
    - `ST.H1.2.1.1` Map core subjects
    - `ST.H1.2.1.2` Add/remove electives
  - *T.H1.2.2 — Define Lesson Units*
    - `ST.H1.2.2.1` Create unit/chapter structure
    - `ST.H1.2.2.2` Assign learning outcomes


##### Section
> Table: `sch_sections` | *tenant_db*

  **F.H1.1 — Academic Session**
  - *T.H1.1.1 — Create Session*
  - *T.H1.1.2 — Activate/Deactivate Session*
  **F.H1.2 — Curriculum Mapping**
  - *T.H1.2.1 — Assign Subjects to Class*
  - *T.H1.2.2 — Define Lesson Units*


##### Class+Section
> Table: `sch_class_section_jnt` | *tenant_db*

  **F.H1.1 — Academic Session**
  - *T.H1.1.1 — Create Session*
  - *T.H1.1.2 — Activate/Deactivate Session*
  **F.H1.2 — Curriculum Mapping**
  - *T.H1.2.1 — Assign Subjects to Class*
  - *T.H1.2.2 — Define Lesson Units*


##### Class Group

  **F.H1.1 — Academic Session**
  - *T.H1.1.1 — Create Session*
  - *T.H1.1.2 — Activate/Deactivate Session*
  **F.H1.2 — Curriculum Mapping**
  - *T.H1.2.1 — Assign Subjects to Class*
  - *T.H1.2.2 — Define Lesson Units*


#### Subject Mgmt.

##### Subject Type
> Table: `sch_subject_types` | *tenant_db*

  **F.H1.1 — Academic Session**
  - *T.H1.1.1 — Create Session*
  - *T.H1.1.2 — Activate/Deactivate Session*
  **F.H1.2 — Curriculum Mapping**
  - *T.H1.2.1 — Assign Subjects to Class*
  - *T.H1.2.2 — Define Lesson Units*


##### Study Format
> Table: `sch_study_formats` | *tenant_db*

  **F.H1.1 — Academic Session**
  - *T.H1.1.1 — Create Session*
  - *T.H1.1.2 — Activate/Deactivate Session*
  **F.H1.2 — Curriculum Mapping**
  - *T.H1.2.1 — Assign Subjects to Class*
  - *T.H1.2.2 — Define Lesson Units*


##### Subject
> Table: `sch_subjects` | *tenant_db*

  **F.H1.1 — Academic Session**
  - *T.H1.1.1 — Create Session*
  - *T.H1.1.2 — Activate/Deactivate Session*
  **F.H1.2 — Curriculum Mapping**
  - *T.H1.2.1 — Assign Subjects to Class*
  - *T.H1.2.2 — Define Lesson Units*


##### Subject + Study Format
> Table: `sch_subject_study_format_jnt` | *tenant_db*

  **F.H1.1 — Academic Session**
  - *T.H1.1.1 — Create Session*
  - *T.H1.1.2 — Activate/Deactivate Session*
  **F.H1.2 — Curriculum Mapping**
  - *T.H1.2.1 — Assign Subjects to Class*
  - *T.H1.2.2 — Define Lesson Units*


##### Subject Class Mapping
> Table: `sch_class_groups_jnt` | *tenant_db*

  **F.H1.1 — Academic Session**
  - *T.H1.1.1 — Create Session*
  - *T.H1.1.2 — Activate/Deactivate Session*
  **F.H1.2 — Curriculum Mapping**
  - *T.H1.2.1 — Assign Subjects to Class*
  - *T.H1.2.2 — Define Lesson Units*


##### Subject Groups
> Table: `sch_subject_groups` | *tenant_db*

  **F.H1.1 — Academic Session**
  - *T.H1.1.1 — Create Session*
  - *T.H1.1.2 — Activate/Deactivate Session*
  **F.H1.2 — Curriculum Mapping**
  - *T.H1.2.1 — Assign Subjects to Class*
  - *T.H1.2.2 — Define Lesson Units*


##### Subjects in Sub. Groups
> Table: `sch_subject_group_subject_jnt` | *tenant_db*

  **F.H1.1 — Academic Session**
  - *T.H1.1.1 — Create Session*
  - *T.H1.1.2 — Activate/Deactivate Session*
  **F.H1.2 — Curriculum Mapping**
  - *T.H1.2.1 — Assign Subjects to Class*
  - *T.H1.2.2 — Define Lesson Units*


### Sylabus

#### Performance Config

##### Class Timetable (Standard)
> Table: `qns_questions_bank`

  **F.G1.1 — Class & Section Setup**
  - *T.G1.1.1 — Configure Academic Structure*
    - `ST.G1.1.1.1` Define classes & sections
    - `ST.G1.1.1.2` Map teachers to class sections
    - `ST.G1.1.1.3` Assign subjects to class/section
  **F.G1.2 — Subject Mapping**
  - *T.G1.2.1 — Assign Subjects*
    - `ST.G1.2.1.1` Map core subjects automatically
    - `ST.G1.2.1.2` Add elective subjects
    - `ST.G1.2.1.3` Set weekly periods for each subject
  **F.G8.1 — Publish Timetable**
  - *T.G8.1.1 — Generate Outputs*
    - `ST.G8.1.1.1` Student timetable PDF
    - `ST.G8.1.1.2` Teacher timetable PDF
    - `ST.G8.1.1.3` Room timetable PDF
  **F.G8.2 — Multi-format Export**
  - *T.G8.2.1 — Export Options*
    - `ST.G8.2.1.1` Excel export
    - `ST.G8.2.1.2` ICS calendar export


##### Teachers Timetable

  **F.G2.1 — Teacher Constraints**
  - *T.G2.1.1 — Define Teacher Availability*
    - `ST.G2.1.1.1` Set available days
    - `ST.G2.1.1.2` Set free/busy slots
    - `ST.G2.1.1.3` Limit max teaching hours per day
  - *T.G2.1.2 — Teacher Preferences*
    - `ST.G2.1.2.1` Preferred periods
    - `ST.G2.1.2.2` Restricted periods
  **F.G2.2 — Workload Allocation**
  - *T.G2.2.1 — Auto Calculate Workload*
    - `ST.G2.2.1.1` Calculate assigned weekly hours
    - `ST.G2.2.1.2` Detect overload or underload
  **F.G8.1 — Publish Timetable**
  - *T.G8.1.1 — Generate Outputs*
  **F.G8.2 — Multi-format Export**
  - *T.G8.2.1 — Export Options*


##### Assign Class Teacher

  **F.G1.1 — Class & Section Setup**
  - *T.G1.1.1 — Configure Academic Structure*
  **F.G1.2 — Subject Mapping**
  - *T.G1.2.1 — Assign Subjects*


##### Lesson Plan

  **F.H2.1 — Lesson Plans**
  - *T.H2.1.1 — Create Lesson Plan*
    - `ST.H2.1.1.1` Define topic & objectives
    - `ST.H2.1.1.2` Attach reference materials
    - `ST.H2.1.1.3` Tag learning outcomes
  - *T.H2.1.2 — Publish Lesson Plan*
    - `ST.H2.1.2.1` Notify students & parents
    - `ST.H2.1.2.2` Track completion of plan
  **F.H2.2 — Digital Content**
  - *T.H2.2.1 — Upload Content*
    - `ST.H2.2.1.1` Upload PDF/Video/SCORM
    - `ST.H2.2.1.2` Add description & metadata
  - *T.H2.2.2 — Content Assignment*
    - `ST.H2.2.2.1` Assign content to class
    - `ST.H2.2.2.2` Schedule content availability


## Student Mgmt.
---

### Student

#### Student Mgmt.

##### Shift student between sections

  **F.E2.1 — Class & Section Allocation**
  - *T.E2.1.1 — Assign Class*
    - `ST.E2.1.1.1` Allocate class & section
    - `ST.E2.1.1.2` Assign roll number automatically
  - *T.E2.1.2 — Modify Class Allocation*
    - `ST.E2.1.2.1` Shift student between sections
    - `ST.E2.1.2.2` Record reason for movement
  **F.E2.2 — Subject Mapping**
  - *T.E2.2.1 — Assign Subjects*
    - `ST.E2.2.1.1` Auto-assign core subjects
    - `ST.E2.2.1.2` Add/remove elective subjects


##### Record Health Details

  **F.E4.1 — Medical Profile**
  - *T.E4.1.1 — Record Health Details*
    - `ST.E4.1.1.1` Add medical conditions
    - `ST.E4.1.1.2` Add allergy information
  - *T.E4.1.2 — Vaccination History*
    - `ST.E4.1.2.1` Record vaccination dates
    - `ST.E4.1.2.2` Upload certificates
  **F.E4.2 — Medical Incidents**
  - *T.E4.2.1 — Record Incident*
    - `ST.E4.2.1.1` Enter incident details
    - `ST.E4.2.1.2` Upload doctor's prescription
  - *T.E4.2.2 — Follow-up Tracking*
    - `ST.E4.2.2.1` Schedule follow-up
    - `ST.E4.2.2.2` Record recovery progress


## Operation Mgmt.
---

### Transport Management

#### Transport masters

##### Vehicle
> Table: `tpt_vehicle`

  **F.N2.1 — Vehicle Master**
  - *T.N2.1.1 — Add Vehicle*
    - `ST.N2.1.1.1` Enter vehicle number & type
    - `ST.N2.1.1.2` Upload RC/insurance documents
  - *T.N2.1.2 — Vehicle Maintenance*
    - `ST.N2.1.2.1` Record service schedule
    - `ST.N2.1.2.2` Track maintenance history
  **F.N2.2 — Driver Profiles**
  - *T.N2.2.1 — Add Driver*
    - `ST.N2.2.1.1` Enter driver license details
    - `ST.N2.2.1.2` Upload ID proof
  - *T.N2.2.2 — Driver Assignment*
    - `ST.N2.2.2.1` Assign driver to vehicle
    - `ST.N2.2.2.2` Track duty schedule


##### Personnel
> Table: `tpt_personnel`

  **F.N2.1 — Vehicle Master**
  - *T.N2.1.1 — Add Vehicle*
  - *T.N2.1.2 — Vehicle Maintenance*
  **F.N2.2 — Driver Profiles**
  - *T.N2.2.1 — Add Driver*
  - *T.N2.2.2 — Driver Assignment*


##### Shift
> Table: `tpt_shift`

  **F.N2.1 — Vehicle Master**
  - *T.N2.1.1 — Add Vehicle*
  - *T.N2.1.2 — Vehicle Maintenance*
  **F.N2.2 — Driver Profiles**
  - *T.N2.2.1 — Add Driver*
  - *T.N2.2.2 — Driver Assignment*


##### Route
> Table: `tpt_route`

  **F.N1.1 — Route Setup**
  - *T.N1.1.1 — Create Route*
    - `ST.N1.1.1.1` Define route name/number
    - `ST.N1.1.1.2` Enter start and end points
    - `ST.N1.1.1.3` Assign driver and vehicle
  - *T.N1.1.2 — Manage Stops*
    - `ST.N1.1.2.1` Add bus stops with geo-coordinates
    - `ST.N1.1.2.2` Set pickup/drop sequence


##### Stopage
> Table: `tpt_pickup_points`

  **F.N1.1 — Route Setup**
  - *T.N1.1.1 — Create Route*
  - *T.N1.1.2 — Manage Stops*


##### Assign Stops to Route
> Table: `tpt_pickup_points_route_jnt`

  **F.N1.1 — Route Setup**
  - *T.N1.1.1 — Create Route*
  - *T.N1.1.2 — Manage Stops*


##### Attendance Device
> Table: `tpt_attendance_device`

  **F.N5.1 — Student Transport Attendance**
  - *T.N5.1.1 — Mark Bus Attendance*
    - `ST.N5.1.1.1` Record boarding status
    - `ST.N5.1.1.2` Auto-sync with school attendance
  **F.N5.2 — Driver Attendance**
  - *T.N5.2.1 — Record Driver Attendance*
    - `ST.N5.2.1.1` Capture check-in/out
    - `ST.N5.2.1.2` Sync with HR attendance module


##### Fine Master
> Table: `tpt_fine_master`

  **F.N6.1 — Fee Mapping**
  - *T.N6.1.1 — Map Route to Fee*
    - `ST.N6.1.1.1` Assign route-wise fee
    - `ST.N6.1.1.2` Auto-calculate monthly charges
  **F.N6.2 — Fee Adjustment**
  - *T.N6.2.1 — Apply Adjustments*
    - `ST.N6.2.1.1` Handle mid-session route change
    - `ST.N6.2.1.2` Apply prorated fees


#### Vehicle Mgmt.

##### Assign Driver & Vehicle to Route
> Table: `tpt_driver_route_vehicle_jnt`

  **F.N2.1 — Vehicle Master**
  - *T.N2.1.1 — Add Vehicle*
  - *T.N2.1.2 — Vehicle Maintenance*
  **F.N2.2 — Driver Profiles**
  - *T.N2.2.1 — Add Driver*
  - *T.N2.2.2 — Driver Assignment*


##### Route Scheduler
> Table: `tpt_route_scheduler_jnt`

  **F.N2.1 — Vehicle Master**
  - *T.N2.1.1 — Add Vehicle*
  - *T.N2.1.2 — Vehicle Maintenance*
  **F.N2.2 — Driver Profiles**
  - *T.N2.2.1 — Add Driver*
  - *T.N2.2.2 — Driver Assignment*


##### Trip Assignment
> Table: `tpt_trip`

  **F.N4.1 — Live Tracking**
  - *T.N4.1.1 — Track Vehicle*
    - `ST.N4.1.1.1` View real-time GPS location
    - `ST.N4.1.1.2` Show route deviation alerts
  **F.N4.2 — Notifications**
  - *T.N4.2.1 — Pickup Alerts*
    - `ST.N4.2.1.1` Notify parents when bus nears stop
    - `ST.N4.2.1.2` Send delay alerts


##### Vehicle Fuel Log
> Table: `tpt_vehicle_fuel_log`

  **F.N2.1 — Vehicle Master**
  - *T.N2.1.1 — Add Vehicle*
  - *T.N2.1.2 — Vehicle Maintenance*
  **F.N2.2 — Driver Profiles**
  - *T.N2.2.1 — Add Driver*
  - *T.N2.2.2 — Driver Assignment*


##### Vehicle Inspection
> Table: `tpt_daily_vehicle_inspection`

  **F.N7.1 — Safety Protocols**
  - *T.N7.1.1 — Record Safety Checklist*
    - `ST.N7.1.1.1` Daily vehicle inspection checklist
    - `ST.N7.1.1.2` Record driver alcohol test
  **F.N7.2 — Compliance Documents**
  - *T.N7.2.1 — Maintain Documents*
    - `ST.N7.2.1.1` Upload vehicle fitness certificate
    - `ST.N7.2.1.2` Track expiry reminders


##### Veh. Service Request
> Table: `tpt_vehicle_service_request`

  **F.N2.1 — Vehicle Master**
  - *T.N2.1.1 — Add Vehicle*
  - *T.N2.1.2 — Vehicle Maintenance*
  **F.N2.2 — Driver Profiles**
  - *T.N2.2.1 — Add Driver*
  - *T.N2.2.2 — Driver Assignment*


##### Vehicle Maintenance
> Table: `tpt_vehicle_maintenance`

  **F.N2.1 — Vehicle Master**
  - *T.N2.1.1 — Add Vehicle*
  - *T.N2.1.2 — Vehicle Maintenance*
  **F.N2.2 — Driver Profiles**
  - *T.N2.2.1 — Add Driver*
  - *T.N2.2.2 — Driver Assignment*


#### Staff Attendance

##### Mannual Attendance
> Table: `tpt_driver_attendance`

  **F.N5.1 — Student Transport Attendance**
  - *T.N5.1.1 — Mark Bus Attendance*
  **F.N5.2 — Driver Attendance**
  - *T.N5.2.1 — Record Driver Attendance*


##### QR Code Attendance
> Table: `tpt_driver_attendance_log`

  **F.N5.1 — Student Transport Attendance**
  - *T.N5.1.1 — Mark Bus Attendance*
  **F.N5.2 — Driver Attendance**
  - *T.N5.2.1 — Record Driver Attendance*


#### Trip Management

##### Trip Detail
> Table: `tpt_trip_stop_detail`

  **F.N4.1 — Live Tracking**
  - *T.N4.1.1 — Track Vehicle*
  **F.N4.2 — Notifications**
  - *T.N4.2.1 — Pickup Alerts*


##### Student Boarding
> Table: `tpt_student_boarding_log`

  **F.N5.1 — Student Transport Attendance**
  - *T.N5.1.1 — Mark Bus Attendance*
  **F.N5.2 — Driver Attendance**
  - *T.N5.2.1 — Record Driver Attendance*


##### Trip Incident
> Table: `tpt_trip_incidents`

  **F.N7.1 — Safety Protocols**
  - *T.N7.1.1 — Record Safety Checklist*
  **F.N7.2 — Compliance Documents**
  - *T.N7.2.1 — Maintain Documents*


#### Student Tranport Mgmt.

##### Std. Transport Allocation
> Table: `tpt_student_route_allocation_jnt`

  **F.N3.1 — Stop Allocation**
  - *T.N3.1.1 — Assign Stop*
    - `ST.N3.1.1.1` Select pickup/drop stop
    - `ST.N3.1.1.2` Define pickup/drop timing
  - *T.N3.1.2 — Change Stop*
    - `ST.N3.1.2.1` Request stop change
    - `ST.N3.1.2.2` Approve/Reject change


##### Transport Fee Detail
> Table: `tpt_student_fee_detail`

  **F.N6.1 — Fee Mapping**
  - *T.N6.1.1 — Map Route to Fee*
  **F.N6.2 — Fee Adjustment**
  - *T.N6.2.1 — Apply Adjustments*


##### Transport Fine Detail
> Table: `tpt_student_fine_detail`

  **F.N6.1 — Fee Mapping**
  - *T.N6.1.1 — Map Route to Fee*
  **F.N6.2 — Fee Adjustment**
  - *T.N6.2.1 — Apply Adjustments*


##### Transport Fee Collection
> Table: `tpt_student_fee_collection`

  **F.N6.1 — Fee Mapping**
  - *T.N6.1.1 — Map Route to Fee*
  **F.N6.2 — Fee Adjustment**
  - *T.N6.2.1 — Apply Adjustments*


##### Payment Log
> Table: `std_student_pay_log`

  **F.N6.1 — Fee Mapping**
  - *T.N6.1.1 — Map Route to Fee*
  **F.N6.2 — Fee Adjustment**
  - *T.N6.2.1 — Apply Adjustments*


#### Transport Notification

##### Transport Report
> Table: `N / A`

  **F.N8.1 — Transport Reports**
  - *T.N8.1.1 — Generate Reports*
    - `ST.N8.1.1.1` Route efficiency report
    - `ST.N8.1.1.2` Vehicle usage report
  **F.N8.2 — AI-Based Optimization**
  - *T.N8.2.1 — Optimize Routes*
    - `ST.N8.2.1.1` Suggest shortest paths
    - `ST.N8.2.1.2` Predict high-traffic delays


##### Transport Notification
> Table: `tpt_notification_log`

  **F.Q3.1 — Push Notification Sending**
  - *T.Q3.1.1 — Send Notification*
    - `ST.Q3.1.1.1` Select notification category
    - `ST.Q3.1.1.2` Add message & deep-link
  - *T.Q3.1.2 — Targeted Notifications*
    - `ST.Q3.1.2.1` Target specific classes/roles
    - `ST.Q3.1.2.2` Set user filters
  **F.Q3.2 — Mobile App Integration**
  - *T.Q3.2.1 — App Token Sync*
    - `ST.Q3.2.1.1` Sync devices with FCM tokens
    - `ST.Q3.2.1.2` Handle invalid tokens


## FrontDesk
---

### Notification

##### Register Notification
> Table: `ntf_notifications`

  **F.Q3.1 — Push Notification Sending**
  - *T.Q3.1.1 — Send Notification*
  - *T.Q3.1.2 — Targeted Notifications*
  **F.Q3.2 — Mobile App Integration**
  - *T.Q3.2.1 — App Token Sync*


##### Notification Channels
> Table: `ntf_notification_channels`

  **F.Q3.1 — Push Notification Sending**
  - *T.Q3.1.1 — Send Notification*
  - *T.Q3.1.2 — Targeted Notifications*
  **F.Q3.2 — Mobile App Integration**
  - *T.Q3.2.1 — App Token Sync*


##### Notification Targets
> Table: `ntf_notification_targets`

  **F.Q3.1 — Push Notification Sending**
  - *T.Q3.1.1 — Send Notification*
  - *T.Q3.1.2 — Targeted Notifications*
  **F.Q3.2 — Mobile App Integration**
  - *T.Q3.2.1 — App Token Sync*


##### User Preference for Notifications
> Table: `ntf_user_preferences`

  **F.Q3.1 — Push Notification Sending**
  - *T.Q3.1.1 — Send Notification*
  - *T.Q3.1.2 — Targeted Notifications*
  **F.Q3.2 — Mobile App Integration**
  - *T.Q3.2.1 — App Token Sync*


##### Notification Templates
> Table: `ntf_templates`

  **F.Q1.1 — Email Sending**
  - *T.Q1.1.1 — Compose Email*
    - `ST.Q1.1.1.1` Select recipients (students/parents/staff)
    - `ST.Q1.1.1.2` Add subject, body & attachments
  - *T.Q1.1.2 — Email Scheduling*
    - `ST.Q1.1.2.1` Schedule email for later
    - `ST.Q1.1.2.2` Set recurring email rules
  **F.Q1.2 — Template Management**
  - *T.Q1.2.1 — Create Email Template*
    - `ST.Q1.2.1.1` Define template name
    - `ST.Q1.2.1.2` Add placeholders for merge fields
  - *T.Q1.2.2 — Manage Templates*
    - `ST.Q1.2.2.1` Edit template content
    - `ST.Q1.2.2.2` Activate/Deactivate template


##### Notification Log
> Table: `ntf_delivery_logs`

  **F.Q7.1 — Message Reports**
  - *T.Q7.1.1 — Generate Report*
    - `ST.Q7.1.1.1` View sent/failed messages
    - `ST.Q7.1.1.2` Filter by date/module
  **F.Q7.2 — Communication Analytics**
  - *T.Q7.2.1 — Analyze Engagement*
    - `ST.Q7.2.1.1` Track open rates
    - `ST.Q7.2.1.2` Identify low-engagement groups


### Admission

#### Admission Enquiry

##### Regiter Enquiry

  **F.C1.1 — Lead Capture**
  - *T.C1.1.1 — Record Enquiry*
    - `ST.C1.1.1.1` Capture student & parent contact details
    - `ST.C1.1.1.2` Select academic year & class sought
    - `ST.C1.1.1.3` Assign lead source (Website, Walk-in, Campaign)
  - *T.C1.1.2 — Lead Assignment*
    - `ST.C1.1.2.1` Assign counselor
    - `ST.C1.1.2.2` Auto-assign based on availability
  **F.C1.2 — Lead Follow-up**
  - *T.C1.2.1 — Follow-up Scheduling*
    - `ST.C1.2.1.1` Schedule call/meeting
    - `ST.C1.2.1.2` Set follow-up reminder
  - *T.C1.2.2 — Lead Status Tracking*
    - `ST.C1.2.2.1` Mark as Interested/Not Interested
    - `ST.C1.2.2.2` Convert to Application


##### Lead Assignment

  **F.C1.1 — Lead Capture**
  - *T.C1.1.1 — Record Enquiry*
  - *T.C1.1.2 — Lead Assignment*
  **F.C1.2 — Lead Follow-up**
  - *T.C1.2.1 — Follow-up Scheduling*
  - *T.C1.2.2 — Lead Status Tracking*


##### Follow-up Scheduling

  **F.C1.1 — Lead Capture**
  - *T.C1.1.1 — Record Enquiry*
  - *T.C1.1.2 — Lead Assignment*
  **F.C1.2 — Lead Follow-up**
  - *T.C1.2.1 — Follow-up Scheduling*
  - *T.C1.2.2 — Lead Status Tracking*


## Support & Maintenance
---

### Complaint Mgmt.

##### Dashboard
> Complaint Dashboard
> Table: `cmp_ai_insights` | *tenant_db*

  **F.D3.1 — Complaint Handling**
  - *T.D3.1.1 — Register Complaint*
    - `ST.D3.1.1.1` Enter complaint details
    - `ST.D3.1.1.2` Assign complaint to staff
  - *T.D3.1.2 — Complaint Resolution*
    - `ST.D3.1.2.1` Update resolution status
    - `ST.D3.1.2.2` Add resolution notes
  **F.D3.2 — Feedback Collection**
  - *T.D3.2.1 — Collect Feedback*
    - `ST.D3.2.1.1` Create feedback form
    - `ST.D3.2.1.2` Collect responses


##### Complaint Category
> CRUD for Complaint Category/Sub-Category
> Table: `cmp_complaint_categories` | *tenant_db*

  **F.D3.1 — Complaint Handling**
  - *T.D3.1.1 — Register Complaint*
  - *T.D3.1.2 — Complaint Resolution*
  **F.D3.2 — Feedback Collection**
  - *T.D3.2.1 — Collect Feedback*


##### Department SLA
> CRUD to capture Department wise Complaint SLA
> Table: `cmp_department_sla` | *tenant_db*

  **F.D3.1 — Complaint Handling**
  - *T.D3.1.1 — Register Complaint*
  - *T.D3.1.2 — Complaint Resolution*
  **F.D3.2 — Feedback Collection**
  - *T.D3.2.1 — Collect Feedback*


##### Register Complaint
> CRUD for Complaint Registration
> Table: `cmp_complaints` | *tenant_db*

  **F.D3.1 — Complaint Handling**
  - *T.D3.1.1 — Register Complaint*
  - *T.D3.1.2 — Complaint Resolution*
  **F.D3.2 — Feedback Collection**
  - *T.D3.2.1 — Collect Feedback*


##### Complaint Log
> View Complaint Log
> Table: `cmp_complaint_actions` | *tenant_db*

  **F.D3.1 — Complaint Handling**
  - *T.D3.1.1 — Register Complaint*
  - *T.D3.1.2 — Complaint Resolution*
  **F.D3.2 — Feedback Collection**
  - *T.D3.2.1 — Collect Feedback*


##### Checkup / Inspection
> CRUD for Checkup / Inspection
> Table: `cmp_medical_checks` | *tenant_db*

  **F.D3.1 — Complaint Handling**
  - *T.D3.1.1 — Register Complaint*
  - *T.D3.1.2 — Complaint Resolution*
  **F.D3.2 — Feedback Collection**
  - *T.D3.2.1 — Collect Feedback*


### Audit Log

#### Vew Activities

##### View Activities
> View with Filter for Activities
> Table: `sys_activity_logs` | *tenant_db*

  **F.A6.1 — System Logs**
  - *T.A6.1.1 — Track Activities*
    - `ST.A6.1.1.1` Log user login/logout
    - `ST.A6.1.1.2` Log data changes
  - *T.A6.1.2 — Export Logs*
    - `ST.A6.1.2.1` Download audit logs CSV
    - `ST.A6.1.2.2` Filter logs by user/date


### Register App Bug

##### Notification

  > ★ *Tasks to be defined — no RBS mapping yet.*


---

# Part 3 — Full RBS Module Index

Complete listing of all modules, sub-modules, and their sub-task counts.
Use these codes when referencing tasks in API design, DB schema, or sprint planning.

**Total unique sub-tasks: 1112**


## Module A — Tenant & System Management (51 sub-tasks)

### A1 — Tenant Registration & Onboarding (10 sub-tasks)

**F.A1.1 — Tenant Creation**
- *T.A1.1.1 — Create Tenant*
  - `ST.A1.1.1.1` Enter school/organization name
  - `ST.A1.1.1.2` Assign tenant code
  - `ST.A1.1.1.3` Capture contact & address details
  - `ST.A1.1.1.4` Upload logo and branding
- *T.A1.1.2 — Configure Default Settings*
  - `ST.A1.1.2.1` Set academic year
  - `ST.A1.1.2.2` Select default country/state/timezone
**F.A1.2 — Subscription Assignment**
- *T.A1.2.1 — Choose Plan*
  - `ST.A1.2.1.1` Select subscription plan
  - `ST.A1.2.1.2` Attach modules enabled in plan
- *T.A1.2.2 — Billing Cycle Setup*
  - `ST.A1.2.2.1` Define billing cycle (Monthly/Yearly)
  - `ST.A1.2.2.2` Set next billing date

### A2 — Tenant Feature Management (4 sub-tasks)

**F.A2.1 — Feature Toggles**
- *T.A2.1.1 — Enable/Disable Modules*
  - `ST.A2.1.1.1` Turn ON/OFF module access
  - `ST.A2.1.1.2` Auto-update user access
- *T.A2.1.2 — Advanced Feature Flags*
  - `ST.A2.1.2.1` Enable premium analytics
  - `ST.A2.1.2.2` Enable AI-based recommendations

### A3 — Authentication & Access Control (6 sub-tasks)

**F.A3.1 — Login & Password Policies**
- *T.A3.1.1 — Password Rules*
  - `ST.A3.1.1.1` Set password strength
  - `ST.A3.1.1.2` Set expiry days
- *T.A3.1.2 — Multi-Factor Authentication*
  - `ST.A3.1.2.1` Enable OTP login
  - `ST.A3.1.2.2` Enable authenticator app
**F.A3.2 — Single Sign-On**
- *T.A3.2.1 — SSO Setup*
  - `ST.A3.2.1.1` Configure OAuth provider
  - `ST.A3.2.1.2` Map user identities

### A4 — User Management (7 sub-tasks)

**F.A4.1 — User Profiles**
- *T.A4.1.1 — Create User*
  - `ST.A4.1.1.1` Enter user details
  - `ST.A4.1.1.2` Assign role
  - `ST.A4.1.1.3` Send invite email
- *T.A4.1.2 — Edit User*
  - `ST.A4.1.2.1` Modify profile details
  - `ST.A4.1.2.2` Update contact information
**F.A4.2 — User Deactivation**
- *T.A4.2.1 — Disable User*
  - `ST.A4.2.1.1` Deactivate login access
  - `ST.A4.2.1.2` Retain historical data

### A5 — Role & Permission Management (6 sub-tasks)

**F.A5.1 — Role Configuration**
- *T.A5.1.1 — Create Role*
  - `ST.A5.1.1.1` Name the role
  - `ST.A5.1.1.2` Assign module permissions
- *T.A5.1.2 — Clone Role*
  - `ST.A5.1.2.1` Duplicate an existing role
  - `ST.A5.1.2.2` Customize permissions
**F.A5.2 — Permission Assignment**
- *T.A5.2.1 — Assign Permissions*
  - `ST.A5.2.1.1` Select CRUD rights
  - `ST.A5.2.1.2` Apply permission to user groups

### A6 — Audit Logs & Monitoring (4 sub-tasks)

**F.A6.1 — System Logs**
- *T.A6.1.1 — Track Activities*
  - `ST.A6.1.1.1` Log user login/logout
  - `ST.A6.1.1.2` Log data changes
- *T.A6.1.2 — Export Logs*
  - `ST.A6.1.2.1` Download audit logs CSV
  - `ST.A6.1.2.2` Filter logs by user/date

### A7 — Notification & Communication Settings (4 sub-tasks)

**F.A7.1 — Notifications**
- *T.A7.1.1 — Email Settings*
  - `ST.A7.1.1.1` Configure SMTP
  - `ST.A7.1.1.2` Set sender signature
- *T.A7.1.2 — SMS Settings*
  - `ST.A7.1.2.1` Add SMS provider API key
  - `ST.A7.1.2.2` Enable template approval

### A8 — Data Privacy & Compliance (6 sub-tasks)

**F.A8.1 — GDPR/Data Protection**
- *T.A8.1.1 — Consent Management*
  - `ST.A8.1.1.1` Configure consent categories (Marketing, Data Sharing)
  - `ST.A8.1.1.2` Record consent timestamps and versions
- *T.A8.1.2 — Right to be Forgotten*
  - `ST.A8.1.2.1` Process data deletion requests
  - `ST.A8.1.2.2` Anonymize vs. delete data based on retention rules
**F.A8.2 — Data Retention Policies**
- *T.A8.2.1 — Define Retention Rules*
  - `ST.A8.2.1.1` Set archival periods for student records post-graduation
  - `ST.A8.2.1.2` Configure automated data purging schedules

### A9 — System Backup & Recovery (4 sub-tasks)

**F.A9.1 — Backup Configuration**
- *T.A9.1.1 — Schedule Backups*
  - `ST.A9.1.1.1` Set daily/weekly backup frequency
  - `ST.A9.1.1.2` Configure backup storage (Local/AWS S3/Google Cloud)
**F.A9.2 — Disaster Recovery**
- *T.A9.2.1 — Recovery Procedures*
  - `ST.A9.2.1.1` Define RTO (Recovery Time Objective) and RPO (Recovery Point Objective)
  - `ST.A9.2.1.2` Create step-by-step recovery playbook for IT team


## Module B — User, Roles & Security (52 sub-tasks)

### B1 — User Profile Management (12 sub-tasks)

**F.B1.1 — User Creation**
- *T.B1.1.1 — Create User Profile*
  - `ST.B1.1.1.1` Enter user details (name, email, phone)
  - `ST.B1.1.1.2` Assign default role
  - `ST.B1.1.1.3` Send activation email
- *T.B1.1.2 — Bulk User Upload*
  - `ST.B1.1.2.1` Upload CSV of users
  - `ST.B1.1.2.2` Map CSV columns to fields
  - `ST.B1.1.2.3` Validate and import users
**F.B1.2 — User Profile Editing**
- *T.B1.2.1 — Edit User Details*
  - `ST.B1.2.1.1` Modify contact information
  - `ST.B1.2.1.2` Update profile photo
  - `ST.B1.2.1.3` Edit personal information
- *T.B1.2.2 — User Status Management*
  - `ST.B1.2.2.1` Activate user
  - `ST.B1.2.2.2` Deactivate user
  - `ST.B1.2.2.3` Lock/Unlock account

### B2 — Role Management (9 sub-tasks)

**F.B2.1 — Role Creation**
- *T.B2.1.1 — Create Role*
  - `ST.B2.1.1.1` Define role name
  - `ST.B2.1.1.2` Add description
  - `ST.B2.1.1.3` Select applicable modules
- *T.B2.1.2 — Clone Role*
  - `ST.B2.1.2.1` Choose existing role
  - `ST.B2.1.2.2` Duplicate permissions
  - `ST.B2.1.2.3` Modify cloned role
**F.B2.2 — Role Assignment**
- *T.B2.2.1 — Assign Role to User*
  - `ST.B2.2.1.1` Select user
  - `ST.B2.2.1.2` Select one or multiple roles
  - `ST.B2.2.1.3` Apply assignment

### B3 — Permission Management (8 sub-tasks)

**F.B3.1 — Module Permissions**
- *T.B3.1.1 — Grant Module Access*
  - `ST.B3.1.1.1` Enable module visibility
  - `ST.B3.1.1.2` Grant create/read/update/delete rights
- *T.B3.1.2 — Restrict Functionality*
  - `ST.B3.1.2.1` Disable sensitive features
  - `ST.B3.1.2.2` Restrict student/fee access
**F.B3.2 — Page-Level Permissions**
- *T.B3.2.1 — Fine-Grained Control*
  - `ST.B3.2.1.1` Enable page access
  - `ST.B3.2.1.2` Disable page elements
- *T.B3.2.2 — UI Element-Level Permissions*
  - `ST.B3.2.2.1` Control button visibility
  - `ST.B3.2.2.2` Restrict action triggers

### B4 — Authentication & Security Policies (7 sub-tasks)

**F.B4.1 — Authentication Rules**
- *T.B4.1.1 — Password Policies*
  - `ST.B4.1.1.1` Define password complexity
  - `ST.B4.1.1.2` Set password expiration days
  - `ST.B4.1.1.3` Force password reset
- *T.B4.1.2 — Login Restrictions*
  - `ST.B4.1.2.1` Limit failed login attempts
  - `ST.B4.1.2.2` Enable IP restrictions
**F.B4.2 — Multi-Factor Authentication**
- *T.B4.2.1 — MFA Setup*
  - `ST.B4.2.1.1` Enable OTP login
  - `ST.B4.2.1.2` Setup authenticator app

### B5 — Session & Device Management (8 sub-tasks)

**F.B5.1 — Session Control**
- *T.B5.1.1 — Session Timeout*
  - `ST.B5.1.1.1` Set inactivity timeout
  - `ST.B5.1.1.2` Auto-logout user
- *T.B5.1.2 — Concurrent Session Limit*
  - `ST.B5.1.2.1` Restrict number of active sessions
  - `ST.B5.1.2.2` Force login revocation
**F.B5.2 — Device Management**
- *T.B5.2.1 — Trusted Devices*
  - `ST.B5.2.1.1` Register new device
  - `ST.B5.2.1.2` Review trusted devices
- *T.B5.2.2 — Block Devices*
  - `ST.B5.2.2.1` Remove device from trusted list
  - `ST.B5.2.2.2` Block future logins from device

### B6 — Audit Logging & Monitoring (8 sub-tasks)

**F.B6.1 — User Activity Logs**
- *T.B6.1.1 — Login/Logout Tracking*
  - `ST.B6.1.1.1` Record login timestamp
  - `ST.B6.1.1.2` Track logout or session timeout
- *T.B6.1.2 — Operation Logs*
  - `ST.B6.1.2.1` Log add/update/delete actions
  - `ST.B6.1.2.2` Store before/after values
**F.B6.2 — Security Audit**
- *T.B6.2.1 — Suspicious Activity Detection*
  - `ST.B6.2.1.1` Flag repeated failed logins
  - `ST.B6.2.1.2` Detect abnormal access patterns
- *T.B6.2.2 — Audit Log Export*
  - `ST.B6.2.2.1` Download logs CSV
  - `ST.B6.2.2.2` Filter logs by date/user/module


## Module C — Admissions & Student Lifecycle (56 sub-tasks)

### C1 — Enquiry & Lead Management (9 sub-tasks)

**F.C1.1 — Lead Capture**
- *T.C1.1.1 — Record Enquiry*
  - `ST.C1.1.1.1` Capture student & parent contact details
  - `ST.C1.1.1.2` Select academic year & class sought
  - `ST.C1.1.1.3` Assign lead source (Website, Walk-in, Campaign)
- *T.C1.1.2 — Lead Assignment*
  - `ST.C1.1.2.1` Assign counselor
  - `ST.C1.1.2.2` Auto-assign based on availability
**F.C1.2 — Lead Follow-up**
- *T.C1.2.1 — Follow-up Scheduling*
  - `ST.C1.2.1.1` Schedule call/meeting
  - `ST.C1.2.1.2` Set follow-up reminder
- *T.C1.2.2 — Lead Status Tracking*
  - `ST.C1.2.2.1` Mark as Interested/Not Interested
  - `ST.C1.2.2.2` Convert to Application

### C2 — Application Management (9 sub-tasks)

**F.C2.1 — Application Form**
- *T.C2.1.1 — Create Application*
  - `ST.C2.1.1.1` Fill student details
  - `ST.C2.1.1.2` Fill parent/guardian info
  - `ST.C2.1.1.3` Upload documents
- *T.C2.1.2 — Application Fees*
  - `ST.C2.1.2.1` Generate application fee challan
  - `ST.C2.1.2.2` Verify fee payment
**F.C2.2 — Application Processing**
- *T.C2.2.1 — Verification*
  - `ST.C2.2.1.1` Verify uploaded documents
  - `ST.C2.2.1.2` Approve/Reject application
- *T.C2.2.2 — Interview Scheduling*
  - `ST.C2.2.2.1` Schedule interview slot
  - `ST.C2.2.2.2` Notify parents via SMS/Email

### C3 — Admission Management (8 sub-tasks)

**F.C3.1 — Admission Offer**
- *T.C3.1.1 — Generate Offer Letter*
  - `ST.C3.1.1.1` Assign admission number
  - `ST.C3.1.1.2` Set joining date
- *T.C3.1.2 — Admission Fee Collection*
  - `ST.C3.1.2.1` Generate admission fee invoice
  - `ST.C3.1.2.2` Confirm payment
**F.C3.2 — Finalize Admission**
- *T.C3.2.1 — Complete Enrollment*
  - `ST.C3.2.1.1` Assign class/section
  - `ST.C3.2.1.2` Generate student ID card
- *T.C3.2.2 — Document Submission*
  - `ST.C3.2.2.1` Collect physical documents
  - `ST.C3.2.2.2` Update mandatory fields

### C4 — Student Profile & Record Management (8 sub-tasks)

**F.C4.1 — Student Profile**
- *T.C4.1.1 — Create Student Profile*
  - `ST.C4.1.1.1` Store personal details
  - `ST.C4.1.1.2` Store address & emergency contacts
- *T.C4.1.2 — Maintain Records*
  - `ST.C4.1.2.1` Track caste/category
  - `ST.C4.1.2.2` Update health information
**F.C4.2 — Student Documents**
- *T.C4.2.1 — Upload Documents*
  - `ST.C4.2.1.1` Upload TC/Marksheets
  - `ST.C4.2.1.2` Upload medical certificate
- *T.C4.2.2 — Document Verification*
  - `ST.C4.2.2.1` Approve authenticity
  - `ST.C4.2.2.2` Update verification status

### C5 — Student Promotion & Alumni (8 sub-tasks)

**F.C5.1 — Promotion Processing**
- *T.C5.1.1 — Generate Promotion List*
  - `ST.C5.1.1.1` Fetch eligible students
  - `ST.C5.1.1.2` Apply promotion criteria
- *T.C5.1.2 — Assign New Class*
  - `ST.C5.1.2.1` Bulk assign promoted class
  - `ST.C5.1.2.2` Generate new session roll numbers
**F.C5.2 — Alumni Management**
- *T.C5.2.1 — Mark as Alumni*
  - `ST.C5.2.1.1` Move student to alumni list
  - `ST.C5.2.1.2` Close active academic records
- *T.C5.2.2 — Issue Transfer Certificate*
  - `ST.C5.2.2.1` Generate TC with details
  - `ST.C5.2.2.2` Track TC issue history

### C6 — Syllabus Management (8 sub-tasks)

**F.C6.1 — Curriculum Configuration**
- *T.C6.1.1 — Add Board/Curriculum*
  - `ST.C6.1.1.1` Define board name (CBSE, ICSE, State Board, IB, Cambridge)
  - `ST.C6.1.1.2` Set board-specific academic calendar patterns
- *T.C6.1.2 — Map Subjects to Board*
  - `ST.C6.1.2.1` Link school subjects to board-specific subject codes
  - `ST.C6.1.2.2` Define credit hours/weightage per board requirement
**F.C6.2 — Syllabus & Lesson Planning**
- *T.C6.2.1 — Create Syllabus Unit*
  - `ST.C6.2.1.1` Define units/chapters with start-end dates
  - `ST.C6.2.1.2` Attach learning objectives and outcomes per unit
- *T.C6.2.2 — Syllabus Progress Tracking*
  - `ST.C6.2.2.1` Track completion percentage vs. planned timeline
  - `ST.C6.2.2.2` Generate alerts for syllabus lag

### C7 — Behavior Assesment (6 sub-tasks)

**F.C7.1 — Incident Management**
- *T.C7.1.1 — Record Disciplinary Incident*
  - `ST.C7.1.1.1` Log incident type (Bullying, Cheating, Disruption)
  - `ST.C7.1.1.2` Assign severity level (Low, Medium, High, Critical)
- *T.C7.1.2 — Action & Follow-up*
  - `ST.C7.1.2.1` Define corrective actions (Warning, Detention, Suspension)
  - `ST.C7.1.2.2` Schedule parent meetings and log outcomes
**F.C7.2 — Behavior Analytics**
- *T.C7.2.1 — Generate Behavior Reports*
  - `ST.C7.2.1.1` Identify patterns (repeat offenders, time/day trends)
  - `ST.C7.2.1.2` Track improvement over time with behavior scores


## Module D — Front Office & Communication (31 sub-tasks)

### D1 — Front Office Desk Management (9 sub-tasks)

**F.D1.1 — Visitor Management**
- *T.D1.1.1 — Register Visitor*
  - `ST.D1.1.1.1` Capture visitor name & contact
  - `ST.D1.1.1.2` Log purpose of visit
  - `ST.D1.1.1.3` Capture in/out time
- *T.D1.1.2 — Visitor Pass*
  - `ST.D1.1.2.1` Generate visitor pass
  - `ST.D1.1.2.2` Print visitor slip
**F.D1.2 — Gate Pass**
- *T.D1.2.1 — Issue Gate Pass*
  - `ST.D1.2.1.1` Create gate pass for students/staff
  - `ST.D1.2.1.2` Capture exit purpose
- *T.D1.2.2 — Gate Pass Approval*
  - `ST.D1.2.2.1` Send approval request to authority
  - `ST.D1.2.2.2` Record approval/rejection

### D2 — Communication Management (8 sub-tasks)

**F.D2.1 — Email Communication**
- *T.D2.1.1 — Send Email*
  - `ST.D2.1.1.1` Select recipients (Students/Staff/Parents)
  - `ST.D2.1.1.2` Attach documents
- *T.D2.1.2 — Email Templates*
  - `ST.D2.1.2.1` Create email templates
  - `ST.D2.1.2.2` Save templates for reuse
**F.D2.2 — SMS Communication**
- *T.D2.2.1 — Send SMS*
  - `ST.D2.2.1.1` Compose SMS message
  - `ST.D2.2.1.2` Select recipients
- *T.D2.2.2 — SMS Logs*
  - `ST.D2.2.2.1` Track delivery reports
  - `ST.D2.2.2.2` Download SMS report

### D3 — Complaint & Feedback Management (6 sub-tasks)

**F.D3.1 — Complaint Handling**
- *T.D3.1.1 — Register Complaint*
  - `ST.D3.1.1.1` Enter complaint details
  - `ST.D3.1.1.2` Assign complaint to staff
- *T.D3.1.2 — Complaint Resolution*
  - `ST.D3.1.2.1` Update resolution status
  - `ST.D3.1.2.2` Add resolution notes
**F.D3.2 — Feedback Collection**
- *T.D3.2.1 — Collect Feedback*
  - `ST.D3.2.1.1` Create feedback form
  - `ST.D3.2.1.2` Collect responses

### D4 — Document & Certificate Issuance (8 sub-tasks)

**F.D4.1 — Certificate Request**
- *T.D4.1.1 — Request Certificate*
  - `ST.D4.1.1.1` Student submits request
  - `ST.D4.1.1.2` Select certificate type
- *T.D4.1.2 — Approval Workflow*
  - `ST.D4.1.2.1` Send request for approval
  - `ST.D4.1.2.2` Track approval stages
**F.D4.2 — Certificate Issuance**
- *T.D4.2.1 — Issue Certificate*
  - `ST.D4.2.1.1` Generate certificate PDF
  - `ST.D4.2.1.2` Print & handover certificate
- *T.D4.2.2 — Record Issuance*
  - `ST.D4.2.2.1` Log certificate number
  - `ST.D4.2.2.2` Store issuance date


## Module E — Student Information System (SIS) (35 sub-tasks)

### E1 — Student Master Data Management (9 sub-tasks)

**F.E1.1 — Student Profile**
- *T.E1.1.1 — Create Student Record*
  - `ST.E1.1.1.1` Enter basic details (Name, DOB, Gender)
  - `ST.E1.1.1.2` Capture parent/guardian information
  - `ST.E1.1.1.3` Assign unique student ID
- *T.E1.1.2 — Edit Student Profile*
  - `ST.E1.1.2.1` Update contact details
  - `ST.E1.1.2.2` Modify demographic information
**F.E1.2 — Student Address & Family**
- *T.E1.2.1 — Manage Address*
  - `ST.E1.2.1.1` Add permanent and correspondence address
  - `ST.E1.2.1.2` Link geo-location for transport planning
- *T.E1.2.2 — Family Information*
  - `ST.E1.2.2.1` Add father/mother/guardian details
  - `ST.E1.2.2.2` Add sibling mapping for discounts

### E2 — Student Academic Information (6 sub-tasks)

**F.E2.1 — Class & Section Allocation**
- *T.E2.1.1 — Assign Class*
  - `ST.E2.1.1.1` Allocate class & section
  - `ST.E2.1.1.2` Assign roll number automatically
- *T.E2.1.2 — Modify Class Allocation*
  - `ST.E2.1.2.1` Shift student between sections
  - `ST.E2.1.2.2` Record reason for movement
**F.E2.2 — Subject Mapping**
- *T.E2.2.1 — Assign Subjects*
  - `ST.E2.2.1.1` Auto-assign core subjects
  - `ST.E2.2.1.2` Add/remove elective subjects

### E3 — Student Attendance Records (6 sub-tasks)

**F.E3.1 — Daily Attendance**
- *T.E3.1.1 — Mark Attendance*
  - `ST.E3.1.1.1` Mark present/absent/late
  - `ST.E3.1.1.2` Record reason for absence
- *T.E3.1.2 — Attendance Corrections*
  - `ST.E3.1.2.1` Allow correction requests
  - `ST.E3.1.2.2` Track edit history
**F.E3.2 — Attendance Reports**
- *T.E3.2.1 — Generate Reports*
  - `ST.E3.2.1.1` Daily attendance report
  - `ST.E3.2.1.2` Monthly & yearly attendance summary

### E4 — Student Health & Medical Records (8 sub-tasks)

**F.E4.1 — Medical Profile**
- *T.E4.1.1 — Record Health Details*
  - `ST.E4.1.1.1` Add medical conditions
  - `ST.E4.1.1.2` Add allergy information
- *T.E4.1.2 — Vaccination History*
  - `ST.E4.1.2.1` Record vaccination dates
  - `ST.E4.1.2.2` Upload certificates
**F.E4.2 — Medical Incidents**
- *T.E4.2.1 — Record Incident*
  - `ST.E4.2.1.1` Enter incident details
  - `ST.E4.2.1.2` Upload doctor's prescription
- *T.E4.2.2 — Follow-up Tracking*
  - `ST.E4.2.2.1` Schedule follow-up
  - `ST.E4.2.2.2` Record recovery progress

### E5 — Parent & Guardian Portal Access (6 sub-tasks)

**F.E5.1 — Parent Accounts**
- *T.E5.1.1 — Create Parent Login*
  - `ST.E5.1.1.1` Link parent to student(s)
  - `ST.E5.1.1.2` Send login credentials
- *T.E5.1.2 — Manage Parent Access*
  - `ST.E5.1.2.1` Enable/disable access
  - `ST.E5.1.2.2` Reset parent password
**F.E5.2 — Parent Communication**
- *T.E5.2.1 — Parent Notifications*
  - `ST.E5.2.1.1` Send fee reminders
  - `ST.E5.2.1.2` Send academic announcements


## Module F — Attendance Management (34 sub-tasks)

### F1 — Student Daily Attendance (10 sub-tasks)

**F.F1.1 — Attendance Marking**
- *T.F1.1.1 — Mark Daily Attendance*
  - `ST.F1.1.1.1` Select class & section
  - `ST.F1.1.1.2` Mark Present/Absent/Late/Half-Day
  - `ST.F1.1.1.3` Record absence reason
- *T.F1.1.2 — Bulk Attendance Entry*
  - `ST.F1.1.2.1` Upload CSV attendance sheet
  - `ST.F1.1.2.2` Validate roll numbers
  - `ST.F1.1.2.3` Auto-update attendance records
**F.F1.2 — Attendance Corrections**
- *T.F1.2.1 — Request Correction*
  - `ST.F1.2.1.1` Student/Parent submit correction request
  - `ST.F1.2.1.2` Attach supporting document
- *T.F1.2.2 — Approve/Reject Correction*
  - `ST.F1.2.2.1` Teacher reviews correction request
  - `ST.F1.2.2.2` Admin final approval with audit log

### F2 — Student Period/Subject Attendance (4 sub-tasks)

**F.F2.1 — Period Attendance**
- *T.F2.1.1 — Mark Period Attendance*
  - `ST.F2.1.1.1` Teacher selects timetable period
  - `ST.F2.1.1.2` Mark attendance per subject
- *T.F2.1.2 — Auto-Fill Features*
  - `ST.F2.1.2.1` Auto-fill present for all
  - `ST.F2.1.2.2` Auto-sync with daily attendance

### F3 — Student Attendance Analytics (6 sub-tasks)

**F.F3.1 — Reports**
- *T.F3.1.1 — Generate Attendance Reports*
  - `ST.F3.1.1.1` Daily attendance report
  - `ST.F3.1.1.2` Monthly/Term-wise attendance summary
- *T.F3.1.2 — Absentee Patterns*
  - `ST.F3.1.2.1` Identify frequent absentees
  - `ST.F3.1.2.2` Detect long absence streaks
**F.F3.2 — Notifications**
- *T.F3.2.1 — Send Alerts*
  - `ST.F3.2.1.1` Send SMS/Email for absence
  - `ST.F3.2.1.2` Auto-alert parents for late arrival

### F4 — Staff Attendance (Teaching & Non-Teaching) (8 sub-tasks)

**F.F4.1 — Staff Check-In/Out**
- *T.F4.1.1 — Mark Staff Attendance*
  - `ST.F4.1.1.1` Record check-in time
  - `ST.F4.1.1.2` Record check-out time
- *T.F4.1.2 — Device Integration*
  - `ST.F4.1.2.1` Sync biometric attendance
  - `ST.F4.1.2.2` Auto-detect anomalies
**F.F4.2 — Leave & Attendance Sync**
- *T.F4.2.1 — Leave Integration*
  - `ST.F4.2.1.1` Auto-mark leave status
  - `ST.F4.2.1.2` Sync approved leave with attendance
- *T.F4.2.2 — Attendance Regularization*
  - `ST.F4.2.2.1` Submit regularization request
  - `ST.F4.2.2.2` Approve/Reject regularization

### F5 — Staff Attendance Analytics (6 sub-tasks)

**F.F5.1 — Reports**
- *T.F5.1.1 — Generate Reports*
  - `ST.F5.1.1.1` Daily staff attendance report
  - `ST.F5.1.1.2` Monthly working hours summary
- *T.F5.1.2 — Department-Level Stats*
  - `ST.F5.1.2.1` Teacher attendance summary
  - `ST.F5.1.2.2` Non-teaching attendance patterns
**F.F5.2 — Alerts**
- *T.F5.2.1 — Late/Early Alerts*
  - `ST.F5.2.1.1` Auto-alert HR for late arrival
  - `ST.F5.2.1.2` Notify department head


## Module G — Advanced Timetable Management (47 sub-tasks)

### G1 — Academic Structure Mapping (6 sub-tasks)

**F.G1.1 — Class & Section Setup**
- *T.G1.1.1 — Configure Academic Structure*
  - `ST.G1.1.1.1` Define classes & sections
  - `ST.G1.1.1.2` Map teachers to class sections
  - `ST.G1.1.1.3` Assign subjects to class/section
**F.G1.2 — Subject Mapping**
- *T.G1.2.1 — Assign Subjects*
  - `ST.G1.2.1.1` Map core subjects automatically
  - `ST.G1.2.1.2` Add elective subjects
  - `ST.G1.2.1.3` Set weekly periods for each subject

### G2 — Teacher Workload & Availability (7 sub-tasks)

**F.G2.1 — Teacher Constraints**
- *T.G2.1.1 — Define Teacher Availability*
  - `ST.G2.1.1.1` Set available days
  - `ST.G2.1.1.2` Set free/busy slots
  - `ST.G2.1.1.3` Limit max teaching hours per day
- *T.G2.1.2 — Teacher Preferences*
  - `ST.G2.1.2.1` Preferred periods
  - `ST.G2.1.2.2` Restricted periods
**F.G2.2 — Workload Allocation**
- *T.G2.2.1 — Auto Calculate Workload*
  - `ST.G2.2.1.1` Calculate assigned weekly hours
  - `ST.G2.2.1.2` Detect overload or underload

### G3 — Room & Resource Constraints (6 sub-tasks)

**F.G3.1 — Room Configuration**
- *T.G3.1.1 — Define Room Details*
  - `ST.G3.1.1.1` Enter capacity
  - `ST.G3.1.1.2` Assign room type (Lab/Classroom)
- *T.G3.1.2 — Room Constraints*
  - `ST.G3.1.2.1` Set availability timeline
  - `ST.G3.1.2.2` Prevent double booking
**F.G3.2 — Resource Allocation**
- *T.G3.2.1 — Assign Resources*
  - `ST.G3.2.1.1` Map labs to subjects
  - `ST.G3.2.1.2` Define special equipment needs

### G4 — Timetable Rule Engine (5 sub-tasks)

**F.G4.1 — Hard Constraints**
- *T.G4.1.1 — Mandatory Rules*
  - `ST.G4.1.1.1` No teacher conflict
  - `ST.G4.1.1.2` No student group conflict
  - `ST.G4.1.1.3` No room conflict
**F.G4.2 — Soft Constraints**
- *T.G4.2.1 — Preference Rules*
  - `ST.G4.2.1.1` Avoid free periods at day start
  - `ST.G4.2.1.2` Balance subject load

### G5 — Automatic Timetable Generation (5 sub-tasks)

**F.G5.1 — Scheduler Engine**
- *T.G5.1.1 — Generate Timetable*
  - `ST.G5.1.1.1` Run auto-allocation engine
  - `ST.G5.1.1.2` Apply recursive conflict resolution
  - `ST.G5.1.1.3` Use heuristic optimization
- *T.G5.1.2 — Validation*
  - `ST.G5.1.2.1` Check unresolved conflicts
  - `ST.G5.1.2.2` Generate conflict summary

### G6 — Manual Timetable Editing (5 sub-tasks)

**F.G6.1 — Drag & Drop Editing**
- *T.G6.1.1 — Modify Timetable*
  - `ST.G6.1.1.1` Move subjects across periods
  - `ST.G6.1.1.2` Swap teacher or room
  - `ST.G6.1.1.3` Override constraints (Admin only)
**F.G6.2 — Conflict Warnings**
- *T.G6.2.1 — Live Conflict Checks*
  - `ST.G6.2.1.1` Teacher conflict alerts
  - `ST.G6.2.1.2` Room capacity conflict alerts

### G7 — Substitution Management (4 sub-tasks)

**F.G7.1 — Absentee Management**
- *T.G7.1.1 — Assign Substitute Teacher*
  - `ST.G7.1.1.1` Auto-suggest substitute
  - `ST.G7.1.1.2` Manual assignment with approval
**F.G7.2 — Teacher Absence Workflow**
- *T.G7.2.1 — Notify Substitutes*
  - `ST.G7.2.1.1` Send SMS/Email
  - `ST.G7.2.1.2` In-app notification

### G8 — Timetable Publishing (5 sub-tasks)

**F.G8.1 — Publish Timetable**
- *T.G8.1.1 — Generate Outputs*
  - `ST.G8.1.1.1` Student timetable PDF
  - `ST.G8.1.1.2` Teacher timetable PDF
  - `ST.G8.1.1.3` Room timetable PDF
**F.G8.2 — Multi-format Export**
- *T.G8.2.1 — Export Options*
  - `ST.G8.2.1.1` Excel export
  - `ST.G8.2.1.2` ICS calendar export

### G9 — Analytics & Reports (4 sub-tasks)

**F.G9.1 — Timetable Reports**
- *T.G9.1.1 — Generate Reports*
  - `ST.G9.1.1.1` Teacher workload report
  - `ST.G9.1.1.2` Room utilization report
**F.G9.2 — AI Insights**
- *T.G9.2.1 — Optimization Suggestions*
  - `ST.G9.2.1.1` Suggest redistribution of load
  - `ST.G9.2.1.2` Highlight conflict-prone times


## Module H — Academics Management (54 sub-tasks)

### H1 — Academic Structure & Curriculum (8 sub-tasks)

**F.H1.1 — Academic Session**
- *T.H1.1.1 — Create Session*
  - `ST.H1.1.1.1` Define academic session name
  - `ST.H1.1.1.2` Set session start & end dates
- *T.H1.1.2 — Activate/Deactivate Session*
  - `ST.H1.1.2.1` Mark session as active
  - `ST.H1.1.2.2` Prevent edits to closed session
**F.H1.2 — Curriculum Mapping**
- *T.H1.2.1 — Assign Subjects to Class*
  - `ST.H1.2.1.1` Map core subjects
  - `ST.H1.2.1.2` Add/remove electives
- *T.H1.2.2 — Define Lesson Units*
  - `ST.H1.2.2.1` Create unit/chapter structure
  - `ST.H1.2.2.2` Assign learning outcomes

### H2 — Lesson Planning & Delivery (9 sub-tasks)

**F.H2.1 — Lesson Plans**
- *T.H2.1.1 — Create Lesson Plan*
  - `ST.H2.1.1.1` Define topic & objectives
  - `ST.H2.1.1.2` Attach reference materials
  - `ST.H2.1.1.3` Tag learning outcomes
- *T.H2.1.2 — Publish Lesson Plan*
  - `ST.H2.1.2.1` Notify students & parents
  - `ST.H2.1.2.2` Track completion of plan
**F.H2.2 — Digital Content**
- *T.H2.2.1 — Upload Content*
  - `ST.H2.2.1.1` Upload PDF/Video/SCORM
  - `ST.H2.2.1.2` Add description & metadata
- *T.H2.2.2 — Content Assignment*
  - `ST.H2.2.2.1` Assign content to class
  - `ST.H2.2.2.2` Schedule content availability

### H3 — Homework & Assignments (9 sub-tasks)

**F.H3.1 — Homework Creation**
- *T.H3.1.1 — Create Homework*
  - `ST.H3.1.1.1` Select class & subject
  - `ST.H3.1.1.2` Enter homework instructions
  - `ST.H3.1.1.3` Attach supporting files
- *T.H3.1.2 — Homework Scheduling*
  - `ST.H3.1.2.1` Set due date
  - `ST.H3.1.2.2` Restrict late submissions
**F.H3.2 — Homework Evaluation**
- *T.H3.2.1 — Review Submission*
  - `ST.H3.2.1.1` View submitted files
  - `ST.H3.2.1.2` Evaluate and grade
- *T.H3.2.2 — Feedback*
  - `ST.H3.2.2.1` Provide written feedback
  - `ST.H3.2.2.2` Send notification to parents

### H4 — Academic Calendar & Events (8 sub-tasks)

**F.H4.1 — Event Management**
- *T.H4.1.1 — Create Academic Event*
  - `ST.H4.1.1.1` Define event name & date
  - `ST.H4.1.1.2` Assign event type
- *T.H4.1.2 — Event Publishing*
  - `ST.H4.1.2.1` Publish to student/parent portals
  - `ST.H4.1.2.2` Send event reminders
**F.H4.2 — Holiday Calendar**
- *T.H4.2.1 — Add Holiday*
  - `ST.H4.2.1.1` Set holiday name
  - `ST.H4.2.1.2` Mark as full or half-day
- *T.H4.2.2 — Holiday Notifications*
  - `ST.H4.2.2.1` Send SMS/email alerts
  - `ST.H4.2.2.2` Auto-apply in attendance

### H5 — Teacher Workload & Distribution (6 sub-tasks)

**F.H5.1 — Workload Calculation**
- *T.H5.1.1 — Calculate Teacher Load*
  - `ST.H5.1.1.1` Compute assigned periods
  - `ST.H5.1.1.2` Check against max load limits
- *T.H5.1.2 — Adjust Load*
  - `ST.H5.1.2.1` Reassign subjects
  - `ST.H5.1.2.2` Balance load across teachers
**F.H5.2 — Load Reports**
- *T.H5.2.1 — Generate Load Report*
  - `ST.H5.2.1.1` Show subject-wise load
  - `ST.H5.2.1.2` Department workload summary

### H6 — Skill & Competency Tracking (8 sub-tasks)

**F.H6.1 — Skill Framework**
- *T.H6.1.1 — Create Skill Categories*
  - `ST.H6.1.1.1` Add cognitive/creative skills
  - `ST.H6.1.1.2` Define descriptors
- *T.H6.1.2 — Assign Skills to Subjects*
  - `ST.H6.1.2.1` Map skills to subject units
  - `ST.H6.1.2.2` Define assessment criteria
**F.H6.2 — Skill Assessment**
- *T.H6.2.1 — Record Skill Performance*
  - `ST.H6.2.1.1` Enter skill rating per student
  - `ST.H6.2.1.2` Attach evidence or notes
- *T.H6.2.2 — Skill Reports*
  - `ST.H6.2.2.1` Download student skill report
  - `ST.H6.2.2.2` Generate skill improvement insights

### H7 — Co-Curricular & Activity Management (6 sub-tasks)

**F.H7.1 — Activity Master**
- *T.H7.1.1 — Create Activity*
  - `ST.H7.1.1.1` Define activity type (Sports, Arts, Club, Competition)
  - `ST.H7.1.1.2` Set activity schedule, venue, and in-charge teacher
- *T.H7.1.2 — Student Participation*
  - `ST.H7.1.2.1` Enroll students in activities
  - `ST.H7.1.2.2` Track attendance and performance in activities
**F.H7.2 — Activity Assessment**
- *T.H7.2.1 — Evaluate Performance*
  - `ST.H7.2.1.1` Record achievements, awards, positions
  - `ST.H7.2.1.2` Generate co-curricular transcripts for students


## Module I — Examination & Gradebook (46 sub-tasks)

### I1 — Exam Structure & Scheme (6 sub-tasks)

**F.I1.1 — Exam Types**
- *T.I1.1.1 — Create Exam Type*
  - `ST.I1.1.1.1` Define exam name (Unit Test, Mid-Term, Final)
  - `ST.I1.1.1.2` Set exam category (Formative/Summative)
- *T.I1.1.2 — Exam Components*
  - `ST.I1.1.2.1` Define theory/practical components
  - `ST.I1.1.2.2` Set max marks per component
**F.I1.2 — Weightage & Scheme**
- *T.I1.2.1 — Define Weightages*
  - `ST.I1.2.1.1` Assign subject-wise weightages
  - `ST.I1.2.1.2` Set grade calculation formula

### I10 — AI-Based Examination Analytics (4 sub-tasks)

**F.I10.1 — Performance Insights**
- *T.I10.1.1 — Analyze Weak Areas*
  - `ST.I10.1.1.1` Identify student skill gaps
  - `ST.I10.1.1.2` Suggest improvement areas
- *T.I10.1.2 — Predictive Alerts*
  - `ST.I10.1.2.1` Predict exam performance risk
  - `ST.I10.1.2.2` Generate AI-based alerts

### I2 — Exam Timetable Scheduling (4 sub-tasks)

**F.I2.1 — Timetable Setup**
- *T.I2.1.1 — Create Exam Slots*
  - `ST.I2.1.1.1` Assign date & time
  - `ST.I2.1.1.2` Attach rooms/invigilation staff
- *T.I2.1.2 — Conflict Checking*
  - `ST.I2.1.2.1` Detect student timetable clashes
  - `ST.I2.1.2.2` Detect invigilator conflicts

### I3 — Marks Entry & Verification (6 sub-tasks)

**F.I3.1 — Marks Entry**
- *T.I3.1.1 — Enter Marks*
  - `ST.I3.1.1.1` Enter marks per student
  - `ST.I3.1.1.2` Support grade-only mode
- *T.I3.1.2 — Bulk Upload*
  - `ST.I3.1.2.1` Upload marks via Excel template
  - `ST.I3.1.2.2` Validate data before import
**F.I3.2 — Marks Verification**
- *T.I3.2.1 — Verify Marks*
  - `ST.I3.2.1.1` Cross-check marks entered
  - `ST.I3.2.1.2` Flag discrepancies

### I4 — Moderation Workflow (4 sub-tasks)

**F.I4.1 — Moderation Review**
- *T.I4.1.1 — Review Marks*
  - `ST.I4.1.1.1` Review marks of borderline students
  - `ST.I4.1.1.2` Suggest moderated marks
- *T.I4.1.2 — Moderation Approval*
  - `ST.I4.1.2.1` Approve/Reject moderation
  - `ST.I4.1.2.2` Record remarks with audit trail

### I5 — Gradebook Calculation Engine (4 sub-tasks)

**F.I5.1 — Grade Calculation**
- *T.I5.1.1 — Calculate Grades*
  - `ST.I5.1.1.1` Apply grade formula
  - `ST.I5.1.1.2` Compute GPA/CGPA
- *T.I5.1.2 — Special Cases*
  - `ST.I5.1.2.1` Process absent students
  - `ST.I5.1.2.2` Apply grace marks

### I6 — Report Cards & Publishing (6 sub-tasks)

**F.I6.1 — Report Generation**
- *T.I6.1.1 — Generate Report Cards*
  - `ST.I6.1.1.1` Generate PDF report card
  - `ST.I6.1.1.2` Apply school branding/templates
- *T.I6.1.2 — Multi-lingual Reports*
  - `ST.I6.1.2.1` Enable bilingual report cards
  - `ST.I6.1.2.2` Apply regional formatting
**F.I6.2 — Publishing**
- *T.I6.2.1 — Publish Results*
  - `ST.I6.2.1.1` Push reports to parent app
  - `ST.I6.2.1.2` Enable download access

### I7 — Promotion & Detention Rules (4 sub-tasks)

**F.I7.1 — Promotion Processing**
- *T.I7.1.1 — Generate Promotion List*
  - `ST.I7.1.1.1` Apply school promotion rules
  - `ST.I7.1.1.2` Identify students for retention
**F.I7.2 — Detention Workflow**
- *T.I7.2.1 — Record Detention*
  - `ST.I7.2.1.1` Mark student as detained
  - `ST.I7.2.1.2` Send notification to parents

### I8 — Board Pattern Support (CBSE/ICSE/IB/Cambridge) (4 sub-tasks)

**F.I8.1 — Board Templates**
- *T.I8.1.1 — Generate Board Report*
  - `ST.I8.1.1.1` Apply CBSE format
  - `ST.I8.1.1.2` Apply ICSE/IB/Cambridge templates
**F.I8.2 — Board Mapping**
- *T.I8.2.1 — Map Subjects*
  - `ST.I8.2.1.1` Map school subjects to board codes
  - `ST.I8.2.1.2` Auto-validate board requirements

### I9 — Custom Report Card Designer (4 sub-tasks)

**F.I9.1 — Template Designer**
- *T.I9.1.1 — Design Template*
  - `ST.I9.1.1.1` Drag & drop fields
  - `ST.I9.1.1.2` Set colors/fonts/borders
- *T.I9.1.2 — Template Management*
  - `ST.I9.1.2.1` Save template version
  - `ST.I9.1.2.2` Assign template to class


## Module J — Fees & Finance Management (57 sub-tasks)

### J1 — Fee Structure & Components (9 sub-tasks)

**F.J1.1 — Fee Heads**
- *T.J1.1.1 — Create Fee Head*
  - `ST.J1.1.1.1` Define fee head name (Tuition, Transport, Hostel)
  - `ST.J1.1.1.2` Assign ledger mapping
  - `ST.J1.1.1.3` Set tax applicability
- *T.J1.1.2 — Manage Fee Head Groups*
  - `ST.J1.1.2.1` Create fee group (Academic, Transport)
  - `ST.J1.1.2.2` Assign fee heads to group
**F.J1.2 — Fee Templates**
- *T.J1.2.1 — Create Fee Structure*
  - `ST.J1.2.1.1` Define class-wise fee amount
  - `ST.J1.2.1.2` Map optional/mandatory heads
- *T.J1.2.2 — Installment Setup*
  - `ST.J1.2.2.1` Define installment dates
  - `ST.J1.2.2.2` Set fine rules

### J10 — Dynamic Fee Structure Engine (4 sub-tasks)

**F.J10.1 — Fee Rule Builder**
- *T.J10.1.1 — Create Fee Rules*
  - `ST.J10.1.1.1` Define rules based on student attributes (Class, Category, Board)
  - `ST.J10.1.1.2` Set conditional logic (e.g., sibling discount if 2+ students)
- *T.J10.1.2 — Rule Testing & Simulation*
  - `ST.J10.1.2.1` Test fee calculation for sample student profiles
  - `ST.J10.1.2.2` Preview fee breakdown before applying to batch

### J2 — Student Fee Assignment (6 sub-tasks)

**F.J2.1 — Fee Allocation**
- *T.J2.1.1 — Assign Fees to Student*
  - `ST.J2.1.1.1` Auto-assign class-wise fees
  - `ST.J2.1.1.2` Apply concession/scholarship
- *T.J2.1.2 — Bulk Fee Allocation*
  - `ST.J2.1.2.1` Upload CSV for mass assignment
  - `ST.J2.1.2.2` Validate student-class mapping
**F.J2.2 — Optional Fee Management**
- *T.J2.2.1 — Elective Fee Assignment*
  - `ST.J2.2.1.1` Select optional fee heads
  - `ST.J2.2.1.2` Apply prorated amount

### J3 — Fee Collection & Receipts (6 sub-tasks)

**F.J3.1 — Collection Entry**
- *T.J3.1.1 — Record Fee Payment*
  - `ST.J3.1.1.1` Select payment mode (Cash/UPI/Bank)
  - `ST.J3.1.1.2` Enter amount & receipt details
- *T.J3.1.2 — Auto Receipt Generation*
  - `ST.J3.1.2.1` Generate receipt number
  - `ST.J3.1.2.2` Send SMS/email confirmation
**F.J3.2 — Online Payments**
- *T.J3.2.1 — Gateway Integration*
  - `ST.J3.2.1.1` Integrate with Razorpay/Paytm
  - `ST.J3.2.1.2` Auto-reconcile online payments

### J4 — Fee Concessions & Discounts (4 sub-tasks)

**F.J4.1 — Concession Rules**
- *T.J4.1.1 — Create Concession*
  - `ST.J4.1.1.1` Define concession type (Sibling, Merit)
  - `ST.J4.1.1.2` Set percentage/amount
- *T.J4.1.2 — Approve Concession*
  - `ST.J4.1.2.1` Send approval request
  - `ST.J4.1.2.2` Record approval history

### J5 — Transport & Hostel Fee Management (8 sub-tasks)

**F.J5.1 — Transport Fees**
- *T.J5.1.1 — Assign Route Fee*
  - `ST.J5.1.1.1` Select route & stop
  - `ST.J5.1.1.2` Auto-calculate monthly fee
- *T.J5.1.2 — Transport Adjustment*
  - `ST.J5.1.2.1` Handle mid-session stop change
  - `ST.J5.1.2.2` Apply pro-rata calculation
**F.J5.2 — Hostel Fees**
- *T.J5.2.1 — Assign Hostel Fee*
  - `ST.J5.2.1.1` Assign room type
  - `ST.J5.2.1.2` Apply mess charges
- *T.J5.2.2 — Hostel Adjustment*
  - `ST.J5.2.2.1` Partial month calculation
  - `ST.J5.2.2.2` Room change adjustment

### J6 — Fine, Penalty & Waiver Management (4 sub-tasks)

**F.J6.1 — Fine Rules**
- *T.J6.1.1 — Set Fine Rule*
  - `ST.J6.1.1.1` Define late fee per day
  - `ST.J6.1.1.2` Set grace period
**F.J6.2 — Waiver Processing**
- *T.J6.2.1 — Approve Waiver*
  - `ST.J6.2.1.1` Record waiver reason
  - `ST.J6.2.1.2` Generate approval log

### J7 — Outstanding & Dues Management (4 sub-tasks)

**F.J7.1 — Dues Tracking**
- *T.J7.1.1 — Calculate Outstanding*
  - `ST.J7.1.1.1` Compute fee pending per student
  - `ST.J7.1.1.2` Identify overdue installments
- *T.J7.1.2 — Auto-Alerts*
  - `ST.J7.1.2.1` Send due reminders
  - `ST.J7.1.2.2` Escalate to admin after multiple misses

### J8 — Fee Reports & Analytics (4 sub-tasks)

**F.J8.1 — Standard Reports**
- *T.J8.1.1 — Generate Reports*
  - `ST.J8.1.1.1` Fee collection summary
  - `ST.J8.1.1.2` Outstanding report
**F.J8.2 — Advanced Analytics**
- *T.J8.2.1 — AI-based Predictions*
  - `ST.J8.2.1.1` Predict fee default risk
  - `ST.J8.2.1.2` Identify patterns in late payments

### J9 — Financial Aid & Scholarship Management (8 sub-tasks)

**F.J9.1 — Scholarship Fund Setup**
- *T.J9.1.1 — Create Scholarship Fund*
  - `ST.J9.1.1.1` Define fund name, sponsor, and total amount
  - `ST.J9.1.1.2` Set eligibility criteria (Academic, Financial Need, Category)
- *T.J9.1.2 — Application Workflow*
  - `ST.J9.1.2.1` Create online scholarship application form
  - `ST.J9.1.2.2` Define review committee and approval stages
**F.J9.2 — Disbursement & Tracking**
- *T.J9.2.1 — Approve & Disburse*
  - `ST.J9.2.1.1` Approve applications and allocate amounts
  - `ST.J9.2.1.2` Auto-apply scholarship to student fee account
- *T.J9.2.2 — Renewal Management*
  - `ST.J9.2.2.1` Track renewal criteria (e.g., maintain certain grades)
  - `ST.J9.2.2.2` Send renewal reminders and process continuations


## Module K — Finance & Accounting (70 sub-tasks)

### K1 — Chart of Accounts (COA) (9 sub-tasks)

**F.K1.1 — Account Groups**
- *T.K1.1.1 — Create Account Group*
  - `ST.K1.1.1.1` Define primary group (Assets/Liabilities/Income/Expense)
  - `ST.K1.1.1.2` Assign accounting nature (Debit/Credit)
- *T.K1.1.2 — Manage Sub-Groups*
  - `ST.K1.1.2.1` Create hierarchical sub-groups
  - `ST.K1.1.2.2` Set posting permissions
**F.K1.2 — Ledger Management**
- *T.K1.2.1 — Create Ledger*
  - `ST.K1.2.1.1` Define ledger name & code
  - `ST.K1.2.1.2` Assign parent account group
  - `ST.K1.2.1.3` Link GST/TAX configuration
- *T.K1.2.2 — Ledger Settings*
  - `ST.K1.2.2.1` Enable reconciliation
  - `ST.K1.2.2.2` Set allowed modules for ledger usage

### K10 — Financial Reporting (5 sub-tasks)

**F.K10.1 — Standard Reports**
- *T.K10.1.1 — Generate Reports*
  - `ST.K10.1.1.1` Trial Balance
  - `ST.K10.1.1.2` Profit & Loss
  - `ST.K10.1.1.3` Balance Sheet
**F.K10.2 — Dashboards**
- *T.K10.2.1 — Finance Dashboard*
  - `ST.K10.2.1.1` Revenue vs Expense analysis
  - `ST.K10.2.1.2` Cashflow trend visualization

### K11 — Integrations (Tally/QuickBooks) (4 sub-tasks)

**F.K11.1 — Tally Integration**
- *T.K11.1.1 — Export Vouchers*
  - `ST.K11.1.1.1` Export JE/Receipts in XML
  - `ST.K11.1.1.2` Download Tally-compatible files
**F.K11.2 — QuickBooks/Zoho**
- *T.K11.2.1 — Sync Accounts*
  - `ST.K11.2.1.1` Synchronize ledgers
  - `ST.K11.2.1.2` Sync transactions via API

### K12 — Budget & Cost Center Management (6 sub-tasks)

**F.K12.1 — Budget Creation**
- *T.K12.1.1 — Define Fiscal Year Budget*
  - `ST.K12.1.1.1` Set overall institutional budget for the fiscal year
  - `ST.K12.1.1.2` Allocate budgets to departments/cost centers (Academics, Sports, Admin)
- *T.K12.1.2 — Budget Tracking*
  - `ST.K12.1.2.1` Record commitments (POs) and actual expenditures against budget
  - `ST.K12.1.2.2` Calculate available balance per cost center in real-time
**F.K12.2 — Budget Reports**
- *T.K12.2.1 — Generate Variance Reports*
  - `ST.K12.2.1.1` Show budget vs. actual spend with variance percentages
  - `ST.K12.2.1.2` Highlight departments exceeding budget thresholds

### K13 — GST & Tax Compliance Engine (6 sub-tasks)

**F.K13.1 — GST Configuration**
- *T.K13.1.1 — Setup Tax Rules*
  - `ST.K13.1.1.1` Define HSN/SAC codes for fee heads and services
  - `ST.K13.1.1.2` Configure tax rates (CGST, SGST, IGST) based on location
- *T.K13.1.2 — E-Invoicing Integration*
  - `ST.K13.1.2.1` Generate IRN (Invoice Reference Number) via government portal
  - `ST.K13.1.2.2` Attach QR code to invoices for verification
**F.K13.2 — GST Return Preparation**
- *T.K13.2.1 — Generate GSTR Reports*
  - `ST.K13.2.1.1` Compile data for GSTR-1 (Outward supplies)
  - `ST.K13.2.1.2` Compile data for GSTR-3B (Summary return)

### K2 — Opening Balances (4 sub-tasks)

**F.K2.1 — Ledger Opening**
- *T.K2.1.1 — Add Opening Balances*
  - `ST.K2.1.1.1` Enter debit/credit opening balance
  - `ST.K2.1.1.2` Validate fiscal year constraints
**F.K2.2 — Student & Vendor Opening**
- *T.K2.2.1 — Import Openings*
  - `ST.K2.2.1.1` Upload outstanding fee CSV
  - `ST.K2.2.1.2` Map vendor outstanding balances

### K3 — Journal Entry Management (6 sub-tasks)

**F.K3.1 — Manual Journals**
- *T.K3.1.1 — Create Journal Entry*
  - `ST.K3.1.1.1` Select debit/credit ledgers
  - `ST.K3.1.1.2` Add narration & attachments
- *T.K3.1.2 — Approval Workflow*
  - `ST.K3.1.2.1` Submit JE for approval
  - `ST.K3.1.2.2` Track approval history
**F.K3.2 — Recurring Journals**
- *T.K3.2.1 — Setup Recurring JE*
  - `ST.K3.2.1.1` Define recurrence cycle
  - `ST.K3.2.1.2` Auto-post according to period

### K4 — Accounts Receivable (AR) (8 sub-tasks)

**F.K4.1 — Student Receivables**
- *T.K4.1.1 — Auto-Post Fee Invoices*
  - `ST.K4.1.1.1` Generate fee JE automatically
  - `ST.K4.1.1.2` Map fee heads to income ledgers
- *T.K4.1.2 — Record Payments*
  - `ST.K4.1.2.1` Accept multi-mode payments
  - `ST.K4.1.2.2` Auto-send receipt to parent
**F.K4.2 — Aging & Collections**
- *T.K4.2.1 — Generate Aging Reports*
  - `ST.K4.2.1.1` Produce 30/60/90-day aging
  - `ST.K4.2.1.2` Identify high-risk accounts
- *T.K4.2.2 — Collection Follow-up*
  - `ST.K4.2.2.1` Send due reminders
  - `ST.K4.2.2.2` Escalate chronic defaulters

### K5 — Accounts Payable (AP) (4 sub-tasks)

**F.K5.1 — Vendor Bills**
- *T.K5.1.1 — Enter Vendor Bill*
  - `ST.K5.1.1.1` Attach bill copy
  - `ST.K5.1.1.2` Verify purchase order linkage
**F.K5.2 — Vendor Payments**
- *T.K5.2.1 — Process Payment*
  - `ST.K5.2.1.1` Select payment mode
  - `ST.K5.2.1.2` Auto-generate payment voucher

### K6 — Vendor Management (4 sub-tasks)

**F.K6.1 — Vendor Profiles**
- *T.K6.1.1 — Create Vendor*
  - `ST.K6.1.1.1` Capture vendor GST/PAN
  - `ST.K6.1.1.2` Store contract terms
**F.K6.2 — Vendor Rating**
- *T.K6.2.1 — Rate Vendor*
  - `ST.K6.2.1.1` Rate quality & delivery time
  - `ST.K6.2.1.2` Update rating based on performance

### K7 — Purchase & Expense Management (4 sub-tasks)

**F.K7.1 — Purchase Orders**
- *T.K7.1.1 — Create PO*
  - `ST.K7.1.1.1` Select vendor & items
  - `ST.K7.1.1.2` Apply tax & discount rules
**F.K7.2 — Expense Claims**
- *T.K7.2.1 — Process Claims*
  - `ST.K7.2.1.1` Upload claim receipts
  - `ST.K7.2.1.2` Approve/Reject staff claims

### K8 — Bank & Cash Management (6 sub-tasks)

**F.K8.1 — Bank Reconciliation**
- *T.K8.1.1 — Import Bank Statement*
  - `ST.K8.1.1.1` Upload CSV/MT940
  - `ST.K8.1.1.2` Auto-match transactions
- *T.K8.1.2 — Reconcile Entries*
  - `ST.K8.1.2.1` Mark matched items
  - `ST.K8.1.2.2` Identify mismatches
**F.K8.2 — Cash Register**
- *T.K8.2.1 — Manage Cashbook*
  - `ST.K8.2.1.1` Record cash inflow/outflow
  - `ST.K8.2.1.2` Track daily cash balance

### K9 — Asset Register & Depreciation (4 sub-tasks)

**F.K9.1 — Asset Register**
- *T.K9.1.1 — Add Asset*
  - `ST.K9.1.1.1` Enter asset details
  - `ST.K9.1.1.2` Assign asset category
**F.K9.2 — Depreciation Engine**
- *T.K9.2.1 — Calculate Depreciation*
  - `ST.K9.2.1.1` Apply SLM/WDV methods
  - `ST.K9.2.1.2` Generate depreciation JE


## Module L — Inventory & Stock Management (50 sub-tasks)

### L1 — Item Master & Categorization (10 sub-tasks)

**F.L1.1 — Item Categories**
- *T.L1.1.1 — Create Category*
  - `ST.L1.1.1.1` Define main category and code
  - `ST.L1.1.1.2` Set parent category
  - `ST.L1.1.1.3` Assign default UOM and tax rules
- *T.L1.1.2 — Manage Category Tree*
  - `ST.L1.1.2.1` Reorder hierarchy
  - `ST.L1.1.2.2` Deactivate category with audit log
**F.L1.2 — Item Master**
- *T.L1.2.1 — Create Item*
  - `ST.L1.2.1.1` Enter item name & SKU
  - `ST.L1.2.1.2` Assign category & UOM
  - `ST.L1.2.1.3` Define min/max stock levels
- *T.L1.2.2 — Item Attributes*
  - `ST.L1.2.2.1` Set brand/model
  - `ST.L1.2.2.2` Enable batch/expiry tracking

### L10 — Asset vs Consumable Handling (4 sub-tasks)

**F.L10.1 — Asset Management**
- *T.L10.1.1 — Register Asset*
  - `ST.L10.1.1.1` Assign asset tag
  - `ST.L10.1.1.2` Record warranty info
**F.L10.2 — Asset Tracking**
- *T.L10.2.1 — Movement Register*
  - `ST.L10.2.1.1` Record asset movement
  - `ST.L10.2.1.2` Generate transfer slip

### L11 — Inventory Reports & Analytics (4 sub-tasks)

**F.L11.1 — Reports**
- *T.L11.1.1 — Stock Reports*
  - `ST.L11.1.1.1` View item-wise stock
  - `ST.L11.1.1.2` Export stock data
**F.L11.2 — Analytics**
- *T.L11.2.1 — Consumption Analytics*
  - `ST.L11.2.1.1` Identify fast-moving items
  - `ST.L11.2.1.2` Predict reorder needs

### L2 — Units of Measurement (UOM) (4 sub-tasks)

**F.L2.1 — UOM Master**
- *T.L2.1.1 — Create UOM*
  - `ST.L2.1.1.1` Define UOM name
  - `ST.L2.1.1.2` Set decimal precision
**F.L2.2 — Conversion Rules**
- *T.L2.2.1 — Define Conversion*
  - `ST.L2.2.1.1` Create conversion factors (BOX → PCS)
  - `ST.L2.2.1.2` Set effective dates

### L3 — Vendor & Supplier Linkage (4 sub-tasks)

**F.L3.1 — Vendor Assignment**
- *T.L3.1.1 — Assign Vendor to Item*
  - `ST.L3.1.1.1` Select preferred vendor
  - `ST.L3.1.1.2` Store last purchase rate
**F.L3.2 — Rate Contracts**
- *T.L3.2.1 — Define Rate Contract*
  - `ST.L3.2.1.1` Set validity dates
  - `ST.L3.2.1.2` Assign item-wise fixed rates

### L4 — Purchase Requisition (PR) (4 sub-tasks)

**F.L4.1 — PR Creation**
- *T.L4.1.1 — Create PR*
  - `ST.L4.1.1.1` Select items and quantities
  - `ST.L4.1.1.2` Enter required date
- *T.L4.1.2 — Upload PR in Bulk*
  - `ST.L4.1.2.1` Upload CSV
  - `ST.L4.1.2.2` Validate PR entries

### L5 — Purchase Order (PO) (4 sub-tasks)

**F.L5.1 — PO Creation**
- *T.L5.1.1 — Convert PR to PO*
  - `ST.L5.1.1.1` Select approved PR lines
  - `ST.L5.1.1.2` Assign supplier & pricing
**F.L5.2 — PO Lifecycle**
- *T.L5.2.1 — Modify PO*
  - `ST.L5.2.1.1` Edit quantities
  - `ST.L5.2.1.2` Record revision history

### L6 — Goods Receipt Note (GRN) (4 sub-tasks)

**F.L6.1 — GRN Processing**
- *T.L6.1.1 — Create GRN*
  - `ST.L6.1.1.1` Verify items received
  - `ST.L6.1.1.2` Record batch/expiry
**F.L6.2 — Quality Check**
- *T.L6.2.1 — QC Process*
  - `ST.L6.2.1.1` Record pass/fail
  - `ST.L6.2.1.2` Add QC notes

### L7 — Stock Ledger & Movement (4 sub-tasks)

**F.L7.1 — Stock Inward**
- *T.L7.1.1 — Post Inward*
  - `ST.L7.1.1.1` Update stock ledger
  - `ST.L7.1.1.2` Record supplier details
**F.L7.2 — Stock Outward**
- *T.L7.2.1 — Issue to Department*
  - `ST.L7.2.1.1` Generate issue slip
  - `ST.L7.2.1.2` Record acknowledgment

### L8 — Stock Issue / Consumption (4 sub-tasks)

**F.L8.1 — Issue Request**
- *T.L8.1.1 — Create Issue Request*
  - `ST.L8.1.1.1` Select items
  - `ST.L8.1.1.2` Set required quantity
**F.L8.2 — Consumption Tracking**
- *T.L8.2.1 — Record Usage*
  - `ST.L8.2.1.1` Update consumed quantity
  - `ST.L8.2.1.2` Track per department

### L9 — Reorder Automation (4 sub-tasks)

**F.L9.1 — Alerts**
- *T.L9.1.1 — Minimum Stock Alert*
  - `ST.L9.1.1.1` Trigger alert when below threshold
  - `ST.L9.1.1.2` Notify store manager
**F.L9.2 — Auto-PR**
- *T.L9.2.1 — Generate Auto PR*
  - `ST.L9.2.1.1` Auto-calc reorder qty
  - `ST.L9.2.1.2` Assign preferred vendor


## Module M — Library Management (37 sub-tasks)

### M1 — Book & Resource Master (9 sub-tasks)

**F.M1.1 — Book Catalog**
- *T.M1.1.1 — Add New Book*
  - `ST.M1.1.1.1` Enter title, author, edition
  - `ST.M1.1.1.2` Assign ISBN/Accession number
  - `ST.M1.1.1.3` Select category & genre
- *T.M1.1.2 — Manage Book Copies*
  - `ST.M1.1.2.1` Add multiple copies
  - `ST.M1.1.2.2` Assign barcodes
**F.M1.2 — Digital Resources**
- *T.M1.2.1 — Add Digital Resource*
  - `ST.M1.2.1.1` Upload e-book/PDF
  - `ST.M1.2.1.2` Enter metadata & tags
- *T.M1.2.2 — Manage Licenses*
  - `ST.M1.2.2.1` Set access restrictions
  - `ST.M1.2.2.2` Define license validity

### M2 — Library Member Management (4 sub-tasks)

**F.M2.1 — Member Profiles**
- *T.M2.1.1 — Register Member*
  - `ST.M2.1.1.1` Link student/staff profile
  - `ST.M2.1.1.2` Assign membership type
- *T.M2.1.2 — Manage Membership*
  - `ST.M2.1.2.1` Renew membership
  - `ST.M2.1.2.2` Deactivate member

### M3 — Book Issue & Return (8 sub-tasks)

**F.M3.1 — Issue Process**
- *T.M3.1.1 — Issue Book*
  - `ST.M3.1.1.1` Scan book barcode
  - `ST.M3.1.1.2` Validate member limits
- *T.M3.1.2 — Due Date Calculation*
  - `ST.M3.1.2.1` Auto-calculate due date
  - `ST.M3.1.2.2` Apply special rules for staff
**F.M3.2 — Return Process**
- *T.M3.2.1 — Return Book*
  - `ST.M3.2.1.1` Scan and update status
  - `ST.M3.2.1.2` Record condition on return
- *T.M3.2.2 — Late Return Handling*
  - `ST.M3.2.2.1` Calculate fine
  - `ST.M3.2.2.2` Add fine to member account

### M4 — Reservations & Hold Requests (4 sub-tasks)

**F.M4.1 — Reservation**
- *T.M4.1.1 — Place Reservation*
  - `ST.M4.1.1.1` Select book to reserve
  - `ST.M4.1.1.2` Check availability
- *T.M4.1.2 — Notify Availability*
  - `ST.M4.1.2.1` Send SMS/email when book is available
  - `ST.M4.1.2.2` Auto-cancel if not collected

### M5 — Inventory & Stock Audit (4 sub-tasks)

**F.M5.1 — Physical Stock Verification**
- *T.M5.1.1 — Perform Stock Audit*
  - `ST.M5.1.1.1` Scan all book barcodes
  - `ST.M5.1.1.2` Identify missing books
**F.M5.2 — Shelf Management**
- *T.M5.2.1 — Assign Shelf Location*
  - `ST.M5.2.1.1` Set aisle/shelf number
  - `ST.M5.2.1.2` Update shelf mapping

### M6 — Fines, Penalties & Payments (4 sub-tasks)

**F.M6.1 — Fine Calculation**
- *T.M6.1.1 — Daily Fine Rules*
  - `ST.M6.1.1.1` Define fine per day
  - `ST.M6.1.1.2` Add grace period
**F.M6.2 — Fine Payment**
- *T.M6.2.1 — Record Fine Payment*
  - `ST.M6.2.1.1` Accept payment
  - `ST.M6.2.1.2` Generate fine receipt

### M7 — Library Reports & Analytics (4 sub-tasks)

**F.M7.1 — Reports**
- *T.M7.1.1 — Generate Reports*
  - `ST.M7.1.1.1` Most issued books report
  - `ST.M7.1.1.2` Overdue books report
**F.M7.2 — Analytics**
- *T.M7.2.1 — Usage Insights*
  - `ST.M7.2.1.1` Identify reading trends
  - `ST.M7.2.1.2` Calculate resource utilization


## Module N — Transport Management (37 sub-tasks)

### N1 — Route & Stop Management (5 sub-tasks)

**F.N1.1 — Route Setup**
- *T.N1.1.1 — Create Route*
  - `ST.N1.1.1.1` Define route name/number
  - `ST.N1.1.1.2` Enter start and end points
  - `ST.N1.1.1.3` Assign driver and vehicle
- *T.N1.1.2 — Manage Stops*
  - `ST.N1.1.2.1` Add bus stops with geo-coordinates
  - `ST.N1.1.2.2` Set pickup/drop sequence

### N2 — Vehicle & Driver Management (8 sub-tasks)

**F.N2.1 — Vehicle Master**
- *T.N2.1.1 — Add Vehicle*
  - `ST.N2.1.1.1` Enter vehicle number & type
  - `ST.N2.1.1.2` Upload RC/insurance documents
- *T.N2.1.2 — Vehicle Maintenance*
  - `ST.N2.1.2.1` Record service schedule
  - `ST.N2.1.2.2` Track maintenance history
**F.N2.2 — Driver Profiles**
- *T.N2.2.1 — Add Driver*
  - `ST.N2.2.1.1` Enter driver license details
  - `ST.N2.2.1.2` Upload ID proof
- *T.N2.2.2 — Driver Assignment*
  - `ST.N2.2.2.1` Assign driver to vehicle
  - `ST.N2.2.2.2` Track duty schedule

### N3 — Student Transport Allocation (4 sub-tasks)

**F.N3.1 — Stop Allocation**
- *T.N3.1.1 — Assign Stop*
  - `ST.N3.1.1.1` Select pickup/drop stop
  - `ST.N3.1.1.2` Define pickup/drop timing
- *T.N3.1.2 — Change Stop*
  - `ST.N3.1.2.1` Request stop change
  - `ST.N3.1.2.2` Approve/Reject change

### N4 — Vehicle Tracking & GPS Monitoring (4 sub-tasks)

**F.N4.1 — Live Tracking**
- *T.N4.1.1 — Track Vehicle*
  - `ST.N4.1.1.1` View real-time GPS location
  - `ST.N4.1.1.2` Show route deviation alerts
**F.N4.2 — Notifications**
- *T.N4.2.1 — Pickup Alerts*
  - `ST.N4.2.1.1` Notify parents when bus nears stop
  - `ST.N4.2.1.2` Send delay alerts

### N5 — Transport Attendance (4 sub-tasks)

**F.N5.1 — Student Transport Attendance**
- *T.N5.1.1 — Mark Bus Attendance*
  - `ST.N5.1.1.1` Record boarding status
  - `ST.N5.1.1.2` Auto-sync with school attendance
**F.N5.2 — Driver Attendance**
- *T.N5.2.1 — Record Driver Attendance*
  - `ST.N5.2.1.1` Capture check-in/out
  - `ST.N5.2.1.2` Sync with HR attendance module

### N6 — Transport Fee Integration (4 sub-tasks)

**F.N6.1 — Fee Mapping**
- *T.N6.1.1 — Map Route to Fee*
  - `ST.N6.1.1.1` Assign route-wise fee
  - `ST.N6.1.1.2` Auto-calculate monthly charges
**F.N6.2 — Fee Adjustment**
- *T.N6.2.1 — Apply Adjustments*
  - `ST.N6.2.1.1` Handle mid-session route change
  - `ST.N6.2.1.2` Apply prorated fees

### N7 — Safety & Compliance (4 sub-tasks)

**F.N7.1 — Safety Protocols**
- *T.N7.1.1 — Record Safety Checklist*
  - `ST.N7.1.1.1` Daily vehicle inspection checklist
  - `ST.N7.1.1.2` Record driver alcohol test
**F.N7.2 — Compliance Documents**
- *T.N7.2.1 — Maintain Documents*
  - `ST.N7.2.1.1` Upload vehicle fitness certificate
  - `ST.N7.2.1.2` Track expiry reminders

### N8 — Reports & Analytics (4 sub-tasks)

**F.N8.1 — Transport Reports**
- *T.N8.1.1 — Generate Reports*
  - `ST.N8.1.1.1` Route efficiency report
  - `ST.N8.1.1.2` Vehicle usage report
**F.N8.2 — AI-Based Optimization**
- *T.N8.2.1 — Optimize Routes*
  - `ST.N8.2.1.1` Suggest shortest paths
  - `ST.N8.2.1.2` Predict high-traffic delays


## Module O — Hostel Management (36 sub-tasks)

### O1 — Hostel & Room Setup (8 sub-tasks)

**F.O1.1 — Hostel Configuration**
- *T.O1.1.1 — Create Hostel*
  - `ST.O1.1.1.1` Define hostel name & address
  - `ST.O1.1.1.2` Assign warden & contact details
- *T.O1.1.2 — Hostel Facilities*
  - `ST.O1.1.2.1` List available facilities
  - `ST.O1.1.2.2` Define facility usage rules
**F.O1.2 — Room Setup**
- *T.O1.2.1 — Create Rooms*
  - `ST.O1.2.1.1` Define room number/type
  - `ST.O1.2.1.2` Set room capacity
- *T.O1.2.2 — Room Allocation Rules*
  - `ST.O1.2.2.1` Set gender-based restrictions
  - `ST.O1.2.2.2` Set priority allocation rules

### O2 — Student Allotment & Movement (4 sub-tasks)

**F.O2.1 — Room Allotment**
- *T.O2.1.1 — Assign Room*
  - `ST.O2.1.1.1` Select student
  - `ST.O2.1.1.2` Assign room & bed number
**F.O2.2 — Room Change Requests**
- *T.O2.2.1 — Handle Requests*
  - `ST.O2.2.1.1` Record room change reason
  - `ST.O2.2.1.2` Approve/Reject request

### O3 — Attendance & In-Out Register (4 sub-tasks)

**F.O3.1 — Daily Attendance**
- *T.O3.1.1 — Record Attendance*
  - `ST.O3.1.1.1` Mark present/absent
  - `ST.O3.1.1.2` Capture late entry remarks
**F.O3.2 — In-Out Register**
- *T.O3.2.1 — Log Movement*
  - `ST.O3.2.1.1` Record out-time & reason
  - `ST.O3.2.1.2` Record in-time

### O4 — Mess Management (4 sub-tasks)

**F.O4.1 — Meal Planning**
- *T.O4.1.1 — Define Weekly Menu*
  - `ST.O4.1.1.1` Set meal plan for week
  - `ST.O4.1.1.2` Assign special diet schedules
**F.O4.2 — Mess Attendance**
- *T.O4.2.1 — Record Meal Attendance*
  - `ST.O4.2.1.1` Track meal consumption
  - `ST.O4.2.1.2` Record special diet served

### O5 — Hostel Fee Management (4 sub-tasks)

**F.O5.1 — Fee Assignment**
- *T.O5.1.1 — Assign Hostel Fee*
  - `ST.O5.1.1.1` Select student & room type
  - `ST.O5.1.1.2` Apply mess charges
**F.O5.2 — Fee Adjustments**
- *T.O5.2.1 — Prorated Fee*
  - `ST.O5.2.1.1` Calculate partial month fee
  - `ST.O5.2.1.2` Apply room change difference

### O6 — Discipline & Incident Management (4 sub-tasks)

**F.O6.1 — Discipline Tracking**
- *T.O6.1.1 — Record Incident*
  - `ST.O6.1.1.1` Enter incident description
  - `ST.O6.1.1.2` Attach supporting documents
**F.O6.2 — Action Workflow**
- *T.O6.2.1 — Issue Warning*
  - `ST.O6.2.1.1` Send warning letter
  - `ST.O6.2.1.2` Notify parents

### O7 — Hostel Inventory Management (4 sub-tasks)

**F.O7.1 — Inventory Tracking**
- *T.O7.1.1 — Record Items*
  - `ST.O7.1.1.1` Add beds/mattresses/tables
  - `ST.O7.1.1.2` Assign condition status
**F.O7.2 — Damage Reporting**
- *T.O7.2.1 — Record Damages*
  - `ST.O7.2.1.1` Log damaged item
  - `ST.O7.2.1.2` Estimate repair cost

### O8 — Reports & Analytics (4 sub-tasks)

**F.O8.1 — Hostel Reports**
- *T.O8.1.1 — Generate Reports*
  - `ST.O8.1.1.1` Hostel occupancy report
  - `ST.O8.1.1.2` Room utilization report
**F.O8.2 — Analytics**
- *T.O8.2.1 — Predict Trends*
  - `ST.O8.2.1.1` Forecast room demand
  - `ST.O8.2.1.2` Identify peak usage months


## Module P — HR & Staff Management (46 sub-tasks)

### P1 — Staff Master & HR Records (9 sub-tasks)

**F.P1.1 — Staff Profile**
- *T.P1.1.1 — Create Staff Profile*
  - `ST.P1.1.1.1` Enter personal details
  - `ST.P1.1.1.2` Upload documents (ID, certificates)
  - `ST.P1.1.1.3` Assign employee code
- *T.P1.1.2 — Edit Staff Profile*
  - `ST.P1.1.2.1` Update contact details
  - `ST.P1.1.2.2` Manage emergency contacts
**F.P1.2 — Job & Employment Details**
- *T.P1.2.1 — Set Employment Details*
  - `ST.P1.2.1.1` Define designation & department
  - `ST.P1.2.1.2` Set joining date & contract type
- *T.P1.2.2 — Document Management*
  - `ST.P1.2.2.1` Upload appointment letter
  - `ST.P1.2.2.2` Track document renewal dates

### P2 — Staff Attendance & Leave (7 sub-tasks)

**F.P2.1 — Leave Management**
- *T.P2.1.1 — Apply Leave*
  - `ST.P2.1.1.1` Select leave type
  - `ST.P2.1.1.2` Submit leave request
  - `ST.P2.1.1.3` Attach supporting document
- *T.P2.1.2 — Leave Approval*
  - `ST.P2.1.2.1` Approve/Reject leave
  - `ST.P2.1.2.2` Record remarks with history
**F.P2.2 — Attendance Integration**
- *T.P2.2.1 — Sync Biometric Attendance*
  - `ST.P2.2.1.1` Fetch logs from biometric device
  - `ST.P2.2.1.2` Auto-mark attendance

### P3 — Payroll Preparation (8 sub-tasks)

**F.P3.1 — Salary Configuration**
- *T.P3.1.1 — Define Salary Structure*
  - `ST.P3.1.1.1` Add earnings & deductions
  - `ST.P3.1.1.2` Assign pay grade
- *T.P3.1.2 — CTC Breakdown*
  - `ST.P3.1.2.1` Auto-calculate components
  - `ST.P3.1.2.2` Record employer contributions
**F.P3.2 — Monthly Payroll**
- *T.P3.2.1 — Generate Payroll*
  - `ST.P3.2.1.1` Calculate earnings & deductions
  - `ST.P3.2.1.2` Apply LOP for absences
- *T.P3.2.2 — Payroll Adjustments*
  - `ST.P3.2.2.1` Add ad-hoc allowances
  - `ST.P3.2.2.2` Apply manual deductions

### P4 — Compliance & Statutory Management (4 sub-tasks)

**F.P4.1 — Statutory Records**
- *T.P4.1.1 — PF & ESI Setup*
  - `ST.P4.1.1.1` Enable PF/ESI applicability
  - `ST.P4.1.1.2` Record employee PF details
- *T.P4.1.2 — Generate Statutory Reports*
  - `ST.P4.1.2.1` PF report
  - `ST.P4.1.2.2` ESI contribution report

### P5 — Performance Appraisal (8 sub-tasks)

**F.P5.1 — Appraisal Setup**
- *T.P5.1.1 — Define KPI Templates*
  - `ST.P5.1.1.1` Add KPI categories
  - `ST.P5.1.1.2` Set weightage for each KPI
- *T.P5.1.2 — Assign Appraisal Cycle*
  - `ST.P5.1.2.1` Set appraisal period
  - `ST.P5.1.2.2` Assign reviewer
**F.P5.2 — Appraisal Execution**
- *T.P5.2.1 — Self Appraisal*
  - `ST.P5.2.1.1` Staff fills self-assessment
  - `ST.P5.2.1.2` Attach proofs
- *T.P5.2.2 — Manager Review*
  - `ST.P5.2.2.1` Score KPIs
  - `ST.P5.2.2.2` Provide final rating

### P6 — Staff Training & Development (6 sub-tasks)

**F.P6.1 — Training Programs**
- *T.P6.1.1 — Create Training Program*
  - `ST.P6.1.1.1` Set topic & trainer
  - `ST.P6.1.1.2` Define training schedule
- *T.P6.1.2 — Enroll Staff*
  - `ST.P6.1.2.1` Add staff to training
  - `ST.P6.1.2.2` Notify participants
**F.P6.2 — Training Evaluation**
- *T.P6.2.1 — Collect Feedback*
  - `ST.P6.2.1.1` Receive training feedback
  - `ST.P6.2.1.2` Generate evaluation report

### P7 — HR Reports & Analytics (4 sub-tasks)

**F.P7.1 — Reports**
- *T.P7.1.1 — Generate Staff Reports*
  - `ST.P7.1.1.1` Staff register
  - `ST.P7.1.1.2` Department-wise strength report
**F.P7.2 — Analytics**
- *T.P7.2.1 — HR Insights*
  - `ST.P7.2.1.1` Attrition rate analysis
  - `ST.P7.2.1.2` Leave trend analysis


## Module Q — Communication & Messaging (44 sub-tasks)

### Q1 — Email Communication (8 sub-tasks)

**F.Q1.1 — Email Sending**
- *T.Q1.1.1 — Compose Email*
  - `ST.Q1.1.1.1` Select recipients (students/parents/staff)
  - `ST.Q1.1.1.2` Add subject, body & attachments
- *T.Q1.1.2 — Email Scheduling*
  - `ST.Q1.1.2.1` Schedule email for later
  - `ST.Q1.1.2.2` Set recurring email rules
**F.Q1.2 — Template Management**
- *T.Q1.2.1 — Create Email Template*
  - `ST.Q1.2.1.1` Define template name
  - `ST.Q1.2.1.2` Add placeholders for merge fields
- *T.Q1.2.2 — Manage Templates*
  - `ST.Q1.2.2.1` Edit template content
  - `ST.Q1.2.2.2` Activate/Deactivate template

### Q2 — SMS Communication (8 sub-tasks)

**F.Q2.1 — SMS Sending**
- *T.Q2.1.1 — Compose SMS*
  - `ST.Q2.1.1.1` Select recipients
  - `ST.Q2.1.1.2` Write SMS within character limit
- *T.Q2.1.2 — Bulk SMS*
  - `ST.Q2.1.2.1` Upload CSV for bulk recipients
  - `ST.Q2.1.2.2` Validate phone numbers
**F.Q2.2 — SMS Gateway Integration**
- *T.Q2.2.1 — Configure Gateway*
  - `ST.Q2.2.1.1` Add API key & sender ID
  - `ST.Q2.2.1.2` Test SMS delivery
- *T.Q2.2.2 — Monitor SMS Logs*
  - `ST.Q2.2.2.1` Track SMS delivery status
  - `ST.Q2.2.2.2` Export SMS logs

### Q3 — Push Notification System (6 sub-tasks)

**F.Q3.1 — Push Notification Sending**
- *T.Q3.1.1 — Send Notification*
  - `ST.Q3.1.1.1` Select notification category
  - `ST.Q3.1.1.2` Add message & deep-link
- *T.Q3.1.2 — Targeted Notifications*
  - `ST.Q3.1.2.1` Target specific classes/roles
  - `ST.Q3.1.2.2` Set user filters
**F.Q3.2 — Mobile App Integration**
- *T.Q3.2.1 — App Token Sync*
  - `ST.Q3.2.1.1` Sync devices with FCM tokens
  - `ST.Q3.2.1.2` Handle invalid tokens

### Q4 — In-App Messaging (6 sub-tasks)

**F.Q4.1 — Chat Messaging**
- *T.Q4.1.1 — Send In-App Message*
  - `ST.Q4.1.1.1` Select user/group
  - `ST.Q4.1.1.2` Send rich-text message
- *T.Q4.1.2 — Chat Attachments*
  - `ST.Q4.1.2.1` Attach images/docs
  - `ST.Q4.1.2.2` Set file size restrictions
**F.Q4.2 — Message Moderation**
- *T.Q4.2.1 — Monitor Chat*
  - `ST.Q4.2.1.1` Flag abusive messages
  - `ST.Q4.2.1.2` Auto-delete flagged content

### Q5 — Announcement & Notice Board (6 sub-tasks)

**F.Q5.1 — Create Announcement**
- *T.Q5.1.1 — Add Notice*
  - `ST.Q5.1.1.1` Enter notice title & details
  - `ST.Q5.1.1.2` Set expiry date
- *T.Q5.1.2 — Attach Files*
  - `ST.Q5.1.2.1` Upload PDF/image
  - `ST.Q5.1.2.2` Restrict file types
**F.Q5.2 — Audience Targeting**
- *T.Q5.2.1 — Select Audience*
  - `ST.Q5.2.1.1` Choose classes/roles
  - `ST.Q5.2.1.2` Enable parent-only announcements

### Q6 — Emergency Alerts (6 sub-tasks)

**F.Q6.1 — Alert Broadcast**
- *T.Q6.1.1 — Send Emergency Alert*
  - `ST.Q6.1.1.1` Select emergency type
  - `ST.Q6.1.1.2` Trigger broadcast via SMS/Email/App
- *T.Q6.1.2 — Alert Priority*
  - `ST.Q6.1.2.1` Mark as high-priority
  - `ST.Q6.1.2.2` Override silent mode
**F.Q6.2 — Alert Logs**
- *T.Q6.2.1 — Record Alert History*
  - `ST.Q6.2.1.1` Store alert time & audience
  - `ST.Q6.2.1.2` Track delivery results

### Q7 — Communication Reports & Analytics (4 sub-tasks)

**F.Q7.1 — Message Reports**
- *T.Q7.1.1 — Generate Report*
  - `ST.Q7.1.1.1` View sent/failed messages
  - `ST.Q7.1.1.2` Filter by date/module
**F.Q7.2 — Communication Analytics**
- *T.Q7.2.1 — Analyze Engagement*
  - `ST.Q7.2.1.1` Track open rates
  - `ST.Q7.2.1.2` Identify low-engagement groups


## Module R — Certificates & Identity Management (52 sub-tasks)

### R1 — Certificate Templates & Configuration (9 sub-tasks)

**F.R1.1 — Template Creation**
- *T.R1.1.1 — Create Certificate Template*
  - `ST.R1.1.1.1` Define layout (header, body, footer)
  - `ST.R1.1.1.2` Add dynamic merge fields (name, class, DOB)
  - `ST.R1.1.1.3` Upload school logo & seal
- *T.R1.1.2 — Design Custom Templates*
  - `ST.R1.1.2.1` Set fonts/colors/borders
  - `ST.R1.1.2.2` Add QR code for verification
**F.R1.2 — Template Management**
- *T.R1.2.1 — Version Control*
  - `ST.R1.2.1.1` Save multiple template versions
  - `ST.R1.2.1.2` Restore older versions
- *T.R1.2.2 — Template Assignment*
  - `ST.R1.2.2.1` Assign template to certificate type
  - `ST.R1.2.2.2` Set permissions for usage

### R2 — Certificate Request Workflow (9 sub-tasks)

**F.R2.1 — Submission**
- *T.R2.1.1 — Request Certificate*
  - `ST.R2.1.1.1` Select certificate type
  - `ST.R2.1.1.2` Enter purpose of request
  - `ST.R2.1.1.3` Attach supporting documents
- *T.R2.1.2 — Track Request*
  - `ST.R2.1.2.1` View request status
  - `ST.R2.1.2.2` Receive updates via SMS/email
**F.R2.2 — Approval Process**
- *T.R2.2.1 — Review Request*
  - `ST.R2.2.1.1` Validate supporting documents
  - `ST.R2.2.1.2` Check student eligibility
- *T.R2.2.2 — Approve/Reject Request*
  - `ST.R2.2.2.1` Record approval remarks
  - `ST.R2.2.2.2` Auto-notify student/parents

### R3 — Certificate Generation & Issuance (8 sub-tasks)

**F.R3.1 — Auto Generation**
- *T.R3.1.1 — Generate Certificate*
  - `ST.R3.1.1.1` Auto-fill merge fields
  - `ST.R3.1.1.2` Apply digital signature
- *T.R3.1.2 — Bulk Generation*
  - `ST.R3.1.2.1` Generate certificates for batch
  - `ST.R3.1.2.2` Download ZIP of certificates
**F.R3.2 — Issuing Process**
- *T.R3.2.1 — Print & Issue*
  - `ST.R3.2.1.1` Print certificate copy
  - `ST.R3.2.1.2` Upload issuance receipt
- *T.R3.2.2 — Record Issuance*
  - `ST.R3.2.2.1` Log certificate number
  - `ST.R3.2.2.2` Track date of issue

### R4 — Document Management System (DMS) (8 sub-tasks)

**F.R4.1 — Document Upload**
- *T.R4.1.1 — Upload Student Document*
  - `ST.R4.1.1.1` Upload PDFs/images
  - `ST.R4.1.1.2` Select document category (TC, Migration, DOB)
- *T.R4.1.2 — Bulk Upload*
  - `ST.R4.1.2.1` Upload documents via ZIP
  - `ST.R4.1.2.2` Map files to students
**F.R4.2 — Document Verification**
- *T.R4.2.1 — Verify Documents*
  - `ST.R4.2.1.1` Review uploaded file
  - `ST.R4.2.1.2` Update verification status
- *T.R4.2.2 — DMS Permissions*
  - `ST.R4.2.2.1` Set access restrictions
  - `ST.R4.2.2.2` Track who viewed/downloaded document

### R5 — Identity Card (ID Card) Management (8 sub-tasks)

**F.R5.1 — ID Card Templates**
- *T.R5.1.1 — Design ID Card Template*
  - `ST.R5.1.1.1` Add student photo field
  - `ST.R5.1.1.2` Set barcode/QR code placement
- *T.R5.1.2 — Template Versions*
  - `ST.R5.1.2.1` Save multiple ID formats
  - `ST.R5.1.2.2` Assign format to class/department
**F.R5.2 — ID Card Generation**
- *T.R5.2.1 — Generate ID Card*
  - `ST.R5.2.1.1` Auto-fetch student details
  - `ST.R5.2.1.2` Apply template layout
- *T.R5.2.2 — Print & Distribution*
  - `ST.R5.2.2.1` Generate printable sheet
  - `ST.R5.2.2.2` Track ID card handover

### R6 — Verification & Authentication System (6 sub-tasks)

**F.R6.1 — QR Code Verification**
- *T.R6.1.1 — Scan QR*
  - `ST.R6.1.1.1` Fetch certificate details
  - `ST.R6.1.1.2` Show authenticity status
- *T.R6.1.2 — Verification Logs*
  - `ST.R6.1.2.1` Record verification attempts
  - `ST.R6.1.2.2` Track verification source
**F.R6.2 — API Verification**
- *T.R6.2.1 — Generate Verification API*
  - `ST.R6.2.1.1` Create API for third-party checks
  - `ST.R6.2.1.2` Secure API with key

### R7 — Reports & Analytics (4 sub-tasks)

**F.R7.1 — Certificate Reports**
- *T.R7.1.1 — Generate Reports*
  - `ST.R7.1.1.1` Issued certificates report
  - `ST.R7.1.1.2` Pending certificates report
**F.R7.2 — Usage Analytics**
- *T.R7.2.1 — Analyze Requests*
  - `ST.R7.2.1.1` Identify peak request periods
  - `ST.R7.2.1.2` Detect frequently requested certificate types


## Module S — Learning Management System (LMS) (53 sub-tasks)

### S1 — Course Management (7 sub-tasks)

**F.S1.1 — Course Setup**
- *T.S1.1.1 — Create Course*
  - `ST.S1.1.1.1` Enter course title & description
  - `ST.S1.1.1.2` Assign subject & grade
  - `ST.S1.1.1.3` Upload course cover image
- *T.S1.1.2 — Course Structure*
  - `ST.S1.1.2.1` Create units & lessons
  - `ST.S1.1.2.2` Define learning objectives
**F.S1.2 — Course Publishing**
- *T.S1.2.1 — Publish Course*
  - `ST.S1.2.1.1` Set course visibility
  - `ST.S1.2.1.2` Notify assigned students

### S10 — Micro-Credentials & Digital Badges (4 sub-tasks)

**F.S10.1 — Badge Design & Issuance**
- *T.S10.1.1 — Design Digital Badge*
  - `ST.S10.1.1.1` Create badge image, name, and description
  - `ST.S10.1.1.2` Define issuance criteria (e.g., complete course with 90%+ score)
- *T.S10.1.2 — Auto-Issue & Display*
  - `ST.S10.1.2.1` Automatically award badge when student meets criteria
  - `ST.S10.1.2.2` Display earned badges on student profile and enable Open Badges export

### S11 — Offline Content & Sync (4 sub-tasks)

**F.S11.1 — Offline Access**
- *T.S11.1.1 — Download for Offline*
  - `ST.S11.1.1.1` Allow students to mark lessons/videos for offline viewing
  - `ST.S11.1.1.2` Store downloaded content encrypted on device
- *T.S11.1.2 — Sync Progress*
  - `ST.S11.1.2.1` Track quiz attempts, progress made offline
  - `ST.S11.1.2.2` Auto-sync data when device reconnects to internet

### S2 — Content Management (4 sub-tasks)

**F.S2.1 — Content Upload**
- *T.S2.1.1 — Upload Learning Content*
  - `ST.S2.1.1.1` Upload PDF/Video/SCORM
  - `ST.S2.1.1.2` Add metadata & tags
**F.S2.2 — Content Organization**
- *T.S2.2.1 — Organize Content*
  - `ST.S2.2.1.1` Drag & drop content ordering
  - `ST.S2.2.1.2` Assign content to lessons

### S3 — Assessment Management (8 sub-tasks)

**F.S3.1 — Quiz Builder**
- *T.S3.1.1 — Create Quiz*
  - `ST.S3.1.1.1` Add MCQ/True-False/Short answer
  - `ST.S3.1.1.2` Set marks & difficulty level
- *T.S3.1.2 — Quiz Settings*
  - `ST.S3.1.2.1` Set time limit
  - `ST.S3.1.2.2` Randomize questions
**F.S3.2 — Assignment Management**
- *T.S3.2.1 — Create Assignment*
  - `ST.S3.2.1.1` Upload instructions
  - `ST.S3.2.1.2` Set submission deadline
- *T.S3.2.2 — Grade Assignment*
  - `ST.S3.2.2.1` Review submissions
  - `ST.S3.2.2.2` Provide scoring & feedback

### S4 — Question Bank Management (4 sub-tasks)

**F.S4.1 — Question Entry**
- *T.S4.1.1 — Add Questions*
  - `ST.S4.1.1.1` Create MCQ/Descriptive questions
  - `ST.S4.1.1.2` Tag difficulty & skill
- *T.S4.1.2 — Bulk Upload*
  - `ST.S4.1.2.1` Upload questions via Excel
  - `ST.S4.1.2.2` Map question fields

### S5 — Tracking & Progress Monitoring (4 sub-tasks)

**F.S5.1 — Learning Progress**
- *T.S5.1.1 — Track Lesson Completion*
  - `ST.S5.1.1.1` Record lesson viewed
  - `ST.S5.1.1.2` Track time spent
**F.S5.2 — Assessment Analytics**
- *T.S5.2.1 — Generate Performance Report*
  - `ST.S5.2.1.1` Analyze quiz scores
  - `ST.S5.2.1.2` Identify weak areas

### S6 — Certificates for Courses (4 sub-tasks)

**F.S6.1 — Certificate Rules**
- *T.S6.1.1 — Set Course Completion Criteria*
  - `ST.S6.1.1.1` Define passing marks
  - `ST.S6.1.1.2` Enable minimum lesson completion
**F.S6.2 — Certificate Generation**
- *T.S6.2.1 — Generate Certificate*
  - `ST.S6.2.1.1` Populate student details
  - `ST.S6.2.1.2` Apply LMS certificate template

### S7 — LMS Reports & Analytics (4 sub-tasks)

**F.S7.1 — Reports**
- *T.S7.1.1 — Course Reports*
  - `ST.S7.1.1.1` Course-wise completion report
  - `ST.S7.1.1.2` Student participation report
**F.S7.2 — AI Insights**
- *T.S7.2.1 — Engagement Predictions*
  - `ST.S7.2.1.1` Predict risk of drop-off
  - `ST.S7.2.1.2` Recommend intervention

### S8 — Adaptive Learning & Recommendation Engine (6 sub-tasks)

**F.S8.1 — Content Tagging & Profiling**
- *T.S8.1.1 — Tag Learning Resources*
  - `ST.S8.1.1.1` Tag videos, PDFs, quizzes with concepts, difficulty levels
  - `ST.S8.1.1.2` Define pre-requisite and post-requisite relationships between resources
- *T.S8.1.2 — Student Learning Profile*
  - `ST.S8.1.2.1` Build profile based on quiz scores, time spent, engagement
  - `ST.S8.1.2.2` Identify knowledge gaps and mastered concepts
**F.S8.2 — AI Recommendations**
- *T.S8.2.1 — Generate Personalized Suggestions*
  - `ST.S8.2.1.1` Recommend "next best" lesson based on profile and goals
  - `ST.S8.2.1.2` Suggest remedial content for weak areas and advanced content for mastery

### S9 — Competency-Based Assessment (4 sub-tasks)

**F.S9.1 — Rubric Management**
- *T.S9.1.1 — Create Assessment Rubric*
  - `ST.S9.1.1.1` Define competency dimensions and performance levels (Novice to Expert)
  - `ST.S9.1.1.2` Attach rubric to assignments, projects, discussions
- *T.S9.1.2 — Evidence-Based Assessment*
  - `ST.S9.1.2.1` Allow students to submit evidence (files, links) against rubric criteria
  - `ST.S9.1.2.2` Enable teacher/peer evaluation using the rubric


## Module SYS — System Administration (12 sub-tasks)

### SYS1 — System Health Monitoring (4 sub-tasks)

**F.SYS1.1 — Dashboard & Alerts**
- *T.SYS1.1.1 — Monitor System Metrics*
  - `ST.SYS1.1.1.1` Display real-time API response times, server CPU/RAM usage, disk space
  - `ST.SYS1.1.1.2` Monitor background job queue (failed, pending jobs) and database connections
- *T.SYS1.1.2 — Configure Alerts*
  - `ST.SYS1.1.2.1` Set thresholds for critical metrics (e.g., CPU >80% for 5 min)
  - `ST.SYS1.1.2.2` Define alert channels (Email, Slack, SMS) for different severity levels

### SYS2 — API & Integration Management (4 sub-tasks)

**F.SYS2.1 — API Key Management**
- *T.SYS2.1.1 — Create & Manage API Keys*
  - `ST.SYS2.1.1.1` Generate API keys for third-party integrations (Biometric, Payment Gateway)
  - `ST.SYS2.1.1.2` Set API key permissions, rate limits, and expiration dates
- *T.SYS2.1.2 — Webhook Configuration*
  - `ST.SYS2.1.2.1` Configure endpoints to receive webhooks from external services
  - `ST.SYS2.1.2.2` View webhook delivery logs and retry failed deliveries

### SYS3 — Data Management (4 sub-tasks)

**F.SYS3.1 — Import/Export Wizards**
- *T.SYS3.1.1 — Bulk Data Import*
  - `ST.SYS3.1.1.1` Upload CSV/Excel files for students, staff, fees with field mapping
  - `ST.SYS3.1.1.2` Validate data format, check for duplicates, and preview before import
- *T.SYS3.1.2 — Data Export & Archival*
  - `ST.SYS3.1.2.1` Export data for specific modules (e.g., all fee transactions for a year)
  - `ST.SYS3.1.2.2` Archive old academic year data to cold storage and update indexes


## Module T — Learner Experience Platform (LXP) (47 sub-tasks)

### T1 — Personalized Learning Paths (7 sub-tasks)

**F.T1.1 — Path Creation**
- *T.T1.1.1 — Create Learning Path*
  - `ST.T1.1.1.1` Select goal or competency target
  - `ST.T1.1.1.2` Add sequence of courses/lessons
  - `ST.T1.1.1.3` Define prerequisites
- *T.T1.1.2 — Path Customization*
  - `ST.T1.1.2.1` Allow learners to reorder items
  - `ST.T1.1.2.2` Enable optional modules
**F.T1.2 — AI-Based Path Suggestions**
- *T.T1.2.1 — Generate Path Suggestions*
  - `ST.T1.2.1.1` Analyze learner profile & behavior
  - `ST.T1.2.1.2` Recommend personalized path

### T2 — Skill Graph & Competency Mapping (6 sub-tasks)

**F.T2.1 — Skill Framework**
- *T.T2.1.1 — Define Skills*
  - `ST.T2.1.1.1` Add technical/cognitive/soft skills
  - `ST.T2.1.1.2` Define skill hierarchy
- *T.T2.1.2 — Map Skills to Content*
  - `ST.T2.1.2.1` Assign skills to lessons
  - `ST.T2.1.2.2` Link assessments to competencies
**F.T2.2 — Skill Tracking**
- *T.T2.2.1 — Track Skill Growth*
  - `ST.T2.2.1.1` Update skill score after assessment
  - `ST.T2.2.1.2` Generate skill radar chart

### T3 — AI Recommendations Engine (4 sub-tasks)

**F.T3.1 — Content Recommendations**
- *T.T3.1.1 — Recommend Content*
  - `ST.T3.1.1.1` Use ML model to recommend next lesson
  - `ST.T3.1.1.2` Rank recommendations based on relevance
**F.T3.2 — Peer-Based Recommendations**
- *T.T3.2.1 — Similar Learner Analysis*
  - `ST.T3.2.1.1` Identify similar learners
  - `ST.T3.2.1.2` Suggest content based on peer success

### T4 — Learning Goals & Roadmaps (4 sub-tasks)

**F.T4.1 — Goal Setting**
- *T.T4.1.1 — Set Learning Goals*
  - `ST.T4.1.1.1` Learner chooses a goal
  - `ST.T4.1.1.2` Define timeline for completion
**F.T4.2 — Goal Tracking**
- *T.T4.2.1 — Track Progress*
  - `ST.T4.2.1.1` View completion bar
  - `ST.T4.2.1.2` Receive milestone reminders

### T5 — Gamification & Engagement (4 sub-tasks)

**F.T5.1 — Badges & Rewards**
- *T.T5.1.1 — Award Badges*
  - `ST.T5.1.1.1` Define badge criteria
  - `ST.T5.1.1.2` Auto-award on achievement
**F.T5.2 — Leaderboards**
- *T.T5.2.1 — Generate Leaderboard*
  - `ST.T5.2.1.1` List top performers
  - `ST.T5.2.1.2` Filter by class/subject

### T6 — Social Learning & Collaboration (6 sub-tasks)

**F.T6.1 — Discussion Forums**
- *T.T6.1.1 — Create Forum*
  - `ST.T6.1.1.1` Define discussion topic
  - `ST.T6.1.1.2` Assign moderator
- *T.T6.1.2 — Thread Management*
  - `ST.T6.1.2.1` Post comments
  - `ST.T6.1.2.2` Upload attachments
**F.T6.2 — Peer Support**
- *T.T6.2.1 — Peer Mentoring*
  - `ST.T6.2.1.1` Assign mentors
  - `ST.T6.2.1.2` Track mentoring sessions

### T7 — Learning Analytics & Insights (4 sub-tasks)

**F.T7.1 — Engagement Analytics**
- *T.T7.1.1 — Track Engagement*
  - `ST.T7.1.1.1` Record time spent per lesson
  - `ST.T7.1.1.2` Identify drop-off points
**F.T7.2 — AI Insights**
- *T.T7.2.1 — Predict Learning Outcomes*
  - `ST.T7.2.1.1` Use ML to predict performance
  - `ST.T7.2.1.2` Generate early warning alerts

### T8 — Mentorship & Career Pathing (8 sub-tasks)

**F.T8.1 — Mentorship Program Setup**
- *T.T8.1.1 — Create Mentorship Program*
  - `ST.T8.1.1.1` Define program goals, duration, and target audience
  - `ST.T8.1.1.2` Set matching criteria (skills, interests, career goals)
- *T.T8.1.2 — Mentor-Mentee Matching*
  - `ST.T8.1.2.1` Auto-suggest mentor-mentee pairs based on criteria
  - `ST.T8.1.2.2` Allow manual override and approval of matches
**F.T8.2 — Mentorship Tracking**
- *T.T8.2.1 — Schedule & Log Sessions*
  - `ST.T8.2.1.1` Book sessions via integrated calendar
  - `ST.T8.2.1.2` Log session notes, goals discussed, and action items
- *T.T8.2.2 — Progress & Feedback*
  - `ST.T8.2.2.1` Track mentee progress towards defined goals
  - `ST.T8.2.2.2` Collect feedback from both mentor and mentee post-program

### T9 — Personalized News & Activity Feed (4 sub-tasks)

**F.T9.1 — Feed Configuration**
- *T.T9.1.1 — Define Content Sources*
  - `ST.T9.1.1.1` Aggregate from announcements, new course materials, peer activity
  - `ST.T9.1.1.2` Include mentor notes, achievement badges, group discussions
- *T.T9.1.2 — Personalization Algorithm*
  - `ST.T9.1.2.1` Rank feed items based on user role, enrolled courses, interests
  - `ST.T9.1.2.2` Prioritize unread/important items and filter out irrelevant content


## Module U — Predictive Analytics & ML Engine (51 sub-tasks)

### U1 — Student Performance Prediction (7 sub-tasks)

**F.U1.1 — Risk Prediction Models**
- *T.U1.1.1 — Predict Academic Risk*
  - `ST.U1.1.1.1` Analyze attendance, marks, engagement
  - `ST.U1.1.1.2` Generate risk score for each student
  - `ST.U1.1.1.3` Identify subjects with potential failure
- *T.U1.1.2 — Early Warning Alerts*
  - `ST.U1.1.2.1` Trigger alerts for high-risk students
  - `ST.U1.1.2.2` Send recommendations to teachers/parents
**F.U1.2 — Performance Insights**
- *T.U1.2.1 — Generate Insights*
  - `ST.U1.2.1.1` Identify weak concepts per student
  - `ST.U1.2.1.2` Highlight performance trends

### U2 — Attendance Forecasting (6 sub-tasks)

**F.U2.1 — Forecast Models**
- *T.U2.1.1 — Predict Absence Probability*
  - `ST.U2.1.1.1` Analyze past attendance & patterns
  - `ST.U2.1.1.2` Predict likelihood of absence
- *T.U2.1.2 — Suggest Interventions*
  - `ST.U2.1.2.1` Generate preventive recommendations
  - `ST.U2.1.2.2` Notify class teachers
**F.U2.2 — Attendance Trends**
- *T.U2.2.1 — Trend Visualization*
  - `ST.U2.2.1.1` Plot weekly/monthly patterns
  - `ST.U2.2.1.2` Highlight anomaly spikes

### U3 — Fee Default Prediction (6 sub-tasks)

**F.U3.1 — Default Prediction Model**
- *T.U3.1.1 — Predict Fee Default Risk*
  - `ST.U3.1.1.1` Analyze payment history
  - `ST.U3.1.1.2` Identify chronic late payers
- *T.U3.1.2 — Automated Alerts*
  - `ST.U3.1.2.1` Notify accounts department
  - `ST.U3.1.2.2` Send automated reminders
**F.U3.2 — Parent Segmentation**
- *T.U3.2.1 — Segment Parents*
  - `ST.U3.2.1.1` Group parents by payment behavior
  - `ST.U3.2.1.2` Identify risk clusters

### U4 — Skill Gap Analysis (8 sub-tasks)

**F.U4.1 — Competency Models**
- *T.U4.1.1 — Analyze Skill Gaps*
  - `ST.U4.1.1.1` Compare skills vs course outcomes
  - `ST.U4.1.1.2` Identify competencies needing improvement
- *T.U4.1.2 — Generate Personalized Actions*
  - `ST.U4.1.2.1` Recommend additional content
  - `ST.U4.1.2.2` Suggest remedial classes
**F.U4.2 — Skill Analytics**
- *T.U4.2.1 — Skill Growth Reports*
  - `ST.U4.2.1.1` Track skill progression
  - `ST.U4.2.1.2` Generate performance dashboards
**F.U4.2 — Institutional Skill Analytics**
- *T.U4.2.1 — Generate Class/Group Reports*
  - `ST.U4.3.1.1` Identify weakest skills per class/section for targeted intervention
  - `ST.U4.3.1.2` Compare skill proficiency across different batches or years

### U5 — Transport Route Optimization (6 sub-tasks)

**F.U5.1 — Route Optimization Model**
- *T.U5.1.1 — Optimize Routes*
  - `ST.U5.1.1.1` Analyze GPS, traffic & stop data
  - `ST.U5.1.1.2` Suggest shortest-time routes
- *T.U5.1.2 — Fuel Efficiency Analytics*
  - `ST.U5.1.2.1` Detect inefficient routes
  - `ST.U5.1.2.2` Predict fuel cost savings
**F.U5.2 — Simulation Engine**
- *T.U5.2.1 — Run Simulations*
  - `ST.U5.2.1.1` Test alternate route plans
  - `ST.U5.2.1.2` Generate comparison reports

### U6 — Resource Allocation Optimization (4 sub-tasks)

**F.U6.1 — Teacher Allocation**
- *T.U6.1.1 — Optimize Workload*
  - `ST.U6.1.1.1` Recommend optimal teacher distribution
  - `ST.U6.1.1.2` Balance teaching hours
**F.U6.2 — Room Allocation**
- *T.U6.2.1 — Suggest Room Assignments*
  - `ST.U6.2.1.1` Match room size to class strength
  - `ST.U6.2.1.2` Avoid laboratory/resource conflicts

### U7 — AI Dashboards & Visualization (6 sub-tasks)

**F.U7.1 — AI Dashboards**
- *T.U7.1.1 — Generate Dashboards*
  - `ST.U7.1.1.1` Display ML predictions
  - `ST.U7.1.1.2` Show insights by module
**F.U7.2 — What-If Analysis**
- *T.U7.2.1 — Scenario Modeling*
  - `ST.U7.2.1.1` Simulate academic/attendance changes
  - `ST.U7.2.1.2` Predict outcome impact
**F.U7.3 — Self-Service Analytics**
- *T.U7.3.1 — Custom Report Builder*
  - `ST.U7.3.1.1` Provide drag-and-drop interface with data fields from all modules
  - `ST.U7.3.1.2` Allow saving and sharing of custom report templates

### U8 — Sentiment & Feedback Analysis (4 sub-tasks)

**F.U8.1 — NLP Processing**
- *T.U8.1.1 — Analyze Open-Ended Feedback*
  - `ST.U8.1.1.1` Process survey comments, complaint descriptions, forum posts
  - `ST.U8.1.1.2` Categorize sentiment (Positive, Neutral, Negative) and identify key themes
**F.U8.2 — Trends & Alerts**
- *T.U8.2.1 — Monitor Sentiment Trends*
  - `ST.U8.2.1.1` Track sentiment changes over time for specific topics (e.g., teaching quality, facilities)
  - `ST.U8.2.1.2` Trigger alerts for sudden negative sentiment spikes

### U9 — Institutional Benchmarking (4 sub-tasks)

**F.U9.1 — KPI Definition & Comparison**
- *T.U9.1.1 — Define Institutional KPIs*
  - `ST.U9.1.1.1` Select metrics (Pass %, Avg. Attendance, Fee Collection Ratio, Teacher Retention)
  - `ST.U9.1.1.2` Set target values and weighting for each KPI
- *T.U9.1.2 — Benchmark Analysis*
  - `ST.U9.1.2.1` Compare school performance against anonymized peer group data
  - `ST.U9.1.2.2` Generate gap analysis report with improvement recommendations


## Module V — SaaS Billing & Subscription (54 sub-tasks)

### V1 — Subscription Plans & Pricing (10 sub-tasks)

**F.V1.1 — Plan Configuration**
- *T.V1.1.1 — Create Subscription Plan*
  - `ST.V1.1.1.1` Define plan name & description
  - `ST.V1.1.1.2` Set pricing (monthly/quarterly/yearly)
  - `ST.V1.1.1.3` Assign included modules/features
- *T.V1.1.2 — Plan Rules*
  - `ST.V1.1.2.1` Define user limits
  - `ST.V1.1.2.2` Set storage limits
  - `ST.V1.1.2.3` Configure overage pricing
**F.V1.2 — Plan Management**
- *T.V1.2.1 — Edit/Update Plan*
  - `ST.V1.2.1.1` Modify pricing & limits
  - `ST.V1.2.1.2` Update feature list
- *T.V1.2.2 — Plan Activation/Deactivation*
  - `ST.V1.2.2.1` Activate plan for sale
  - `ST.V1.2.2.2` Retire old plan versions

### V2 — Tenant Subscription Assignment (9 sub-tasks)

**F.V2.1 — Subscription Purchase**
- *T.V2.1.1 — Assign Plan to Tenant*
  - `ST.V2.1.1.1` Select subscription plan
  - `ST.V2.1.1.2` Set start/end date
  - `ST.V2.1.1.3` Configure billing cycle
- *T.V2.1.2 — Trial Management*
  - `ST.V2.1.2.1` Enable trial period
  - `ST.V2.1.2.2` Auto‑convert trial to paid subscription
**F.V2.2 — Subscription Lifecycle**
- *T.V2.2.1 — Renewal Management*
  - `ST.V2.2.1.1` Auto‑renew subscription
  - `ST.V2.2.1.2` Notify tenant for manual renewal
- *T.V2.2.2 — Upgrade/Downgrade*
  - `ST.V2.2.2.1` Switch plan mid‑cycle
  - `ST.V2.2.2.2` Apply prorated charges

### V3 — Billing Engine (9 sub-tasks)

**F.V3.1 — Invoice Generation**
- *T.V3.1.1 — Generate Invoice*
  - `ST.V3.1.1.1` Create recurring invoice
  - `ST.V3.1.1.2` Include addons/overage usage
  - `ST.V3.1.1.3` Apply taxes as per region
- *T.V3.1.2 — Invoice Scheduling*
  - `ST.V3.1.2.1` Schedule monthly/annual billing
  - `ST.V3.1.2.2` Send reminders for unpaid invoices
**F.V3.2 — Payment Processing**
- *T.V3.2.1 — Record Payment*
  - `ST.V3.2.1.1` Accept online payment (UPI/Card)
  - `ST.V3.2.1.2` Record offline payment (NEFT/Cash)
- *T.V3.2.2 — Auto‑Reconciliation*
  - `ST.V3.2.2.1` Match payment with invoice automatically
  - `ST.V3.2.2.2` Flag mismatched transactions

### V4 — Metering, Usage & Overage Tracking (6 sub-tasks)

**F.V4.1 — Usage Monitoring**
- *T.V4.1.1 — Track Resource Usage*
  - `ST.V4.1.1.1` Monitor API calls
  - `ST.V4.1.1.2` Track storage consumption
- *T.V4.1.2 — Overage Alerts*
  - `ST.V4.1.2.1` Notify tenant when nearing limits
  - `ST.V4.1.2.2` Auto‑lock premium features when exceeded
**F.V4.2 — Overage Billing**
- *T.V4.2.1 — Calculate Overage Charges*
  - `ST.V4.2.1.1` Multiply usage above threshold
  - `ST.V4.2.1.2` Apply overage invoice line items

### V5 — Payment Gateways & Integrations (6 sub-tasks)

**F.V5.1 — Gateway Setup**
- *T.V5.1.1 — Configure Gateway*
  - `ST.V5.1.1.1` Add API keys for Razorpay/Stripe/PayPal
  - `ST.V5.1.1.2` Set webhook URL for payment confirmation
- *T.V5.1.2 — Gateway Testing*
  - `ST.V5.1.2.1` Send test payment request
  - `ST.V5.1.2.2` Verify webhook response
**F.V5.2 — Multi‑Currency Support**
- *T.V5.2.1 — Enable Currencies*
  - `ST.V5.2.1.1` Configure supported currencies
  - `ST.V5.2.1.2` Set exchange rate source

### V6 — Tenant Billing Portal (8 sub-tasks)

**F.V6.1 — Billing Dashboard**
- *T.V6.1.1 — View Billing History*
  - `ST.V6.1.1.1` Display invoices list
  - `ST.V6.1.1.2` Filter by paid/unpaid
- *T.V6.1.2 — View Usage Summary*
  - `ST.V6.1.2.1` Show API/storage usage
  - `ST.V6.1.2.2` Highlight overage areas
**F.V6.2 — Self‑Service Payments**
- *T.V6.2.1 — Download Invoice*
  - `ST.V6.2.1.1` Download invoice PDF
  - `ST.V6.2.1.2` Download payment receipt
- *T.V6.2.2 — Make Online Payment*
  - `ST.V6.2.2.1` Redirect to online payment gateway
  - `ST.V6.2.2.2` Update payment status in system

### V7 — SaaS Compliance & Audit (6 sub-tasks)

**F.V7.1 — Audit Logs**
- *T.V7.1.1 — Track Billing Events*
  - `ST.V7.1.1.1` Record invoice creation
  - `ST.V7.1.1.2` Log payment confirmations
- *T.V7.1.2 — Track Subscription Updates*
  - `ST.V7.1.2.1` Record plan upgrade/downgrade
  - `ST.V7.1.2.2` Maintain full audit trail
**F.V7.2 — Compliance Reports**
- *T.V7.2.1 — Generate Compliance Report*
  - `ST.V7.2.1.1` GST/Tax reports
  - `ST.V7.2.1.2` Country‑wise billing summaries


## Module W — Cafeteria & Mess Management (12 sub-tasks)

### W1 — Digital Menu Management (4 sub-tasks)

**F.W1.1 — Weekly Menu Planner**
- *T.W1.1.1 — Create Meal Plan*
  - `ST.W1.1.1.1` Add dishes with detailed descriptions, nutritional info, and allergen warnings
  - `ST.W1.1.1.2` Assign meal plan to specific days and meal types (Breakfast, Lunch, Snacks)
- *T.W1.1.2 — Publish & Notify*
  - `ST.W1.1.2.1` Publish weekly menu to parent/student portal
  - `ST.W1.1.2.2` Send push notification/SMS alert for menu updates

### W2 — Online Ordering & Pre-Booking (4 sub-tasks)

**F.W2.1 — Meal Pre-Ordering**
- *T.W2.1.1 — Student/Parent Order Interface*
  - `ST.W2.1.1.1` Browse weekly menu and select meals for upcoming days
  - `ST.W2.1.1.2` Specify special dietary requirements (e.g., Jain, No onion-garlic)
- *T.W2.1.2 — Order Management*
  - `ST.W2.1.2.1` View consolidated order list for kitchen preparation
  - `ST.W2.1.2.2` Close ordering window before meal time (e.g., 2 hours before lunch)

### W3 — Inventory & Kitchen Stock (4 sub-tasks)

**F.W3.1 — Stock Management**
- *T.W3.1.1 — Manage Raw Materials*
  - `ST.W3.1.1.1` Record inventory of grains, pulses, vegetables, spices
  - `ST.W3.1.1.2` Set reorder levels and generate purchase requests automatically
- *T.W3.1.2 — Consumption Tracking*
  - `ST.W3.1.2.1` Log actual consumption against planned meals
  - `ST.W3.1.2.2` Calculate food cost and wastage reports


## Module X — Visitor & Security Management (12 sub-tasks)

### X1 — Digital Visitor Registration (4 sub-tasks)

**F.X1.1 — Pre-Registration**
- *T.X1.1.1 — Visitor Pre-Registration*
  - `ST.X1.1.1.1` Allow hosts to pre-register visitors with details (name, phone, purpose, vehicle)
  - `ST.X1.1.1.2` Send pre-registration QR code to visitor via SMS/Email
- *T.X1.1.2 — Walking Registration*
  - `ST.X1.1.2.1` Register walk-in visitors at reception/kiosk
  - `ST.X1.1.2.2` Capture visitor photo and ID proof scan

### X2 — Gate Security Integration (4 sub-tasks)

**F.X2.1 — Check-in/Check-out**
- *T.X2.1.1 — Process Visitor Entry*
  - `ST.X2.1.1.1` Security scans QR code (pre-reg or on-site) at gate
  - `ST.X2.1.1.2` System records check-in time, captures live photo, prints temporary badge
- *T.X2.1.2 — Visitor Exit*
  - `ST.X2.1.2.1` Scan badge/QR code at exit to record check-out time
  - `ST.X2.1.2.2` Flag overdue visitors (still inside beyond expected duration)

### X3 — Security Alerts & Monitoring (4 sub-tasks)

**F.X3.1 — Real-time Dashboard**
- *T.X3.1.1 — Monitor Campus Activity*
  - `ST.X3.1.1.1` Display live count of visitors on campus, current check-ins
  - `ST.X3.1.1.2` Show list of visitors with expired time or in restricted zones
**F.X3.2 — Emergency Alerts**
- *T.X3.2.1 — Broadcast Emergency*
  - `ST.X3.2.1.1` Send instant SMS/App alert to all staff for lockdown, evacuation
  - `ST.X3.2.1.2` Initiate automated roll call or headcount procedure via system


## Module Y — Maintenance & Facility Helpdesk (12 sub-tasks)

### Y1 — Ticketing System (8 sub-tasks)

**F.Y1.1 — Issue Reporting**
- *T.Y1.1.1 — Create Maintenance Ticket*
  - `ST.Y1.1.1.1` Staff/Student selects category (Electrical, Plumbing, Carpenter, IT, Cleaning)
  - `ST.Y1.1.1.2` Provide detailed description, location (Room/Building), and upload photos
- *T.Y1.1.2 — Ticket Prioritization*
  - `ST.Y1.1.2.1` Auto-assign priority based on category and keywords (e.g., "water leakage" = High)
  - `ST.Y1.1.2.2` Allow manual override of priority by admin
**F.Y1.2 — Work Assignment & Tracking**
- *T.Y1.2.1 — Assign to Technician*
  - `ST.Y1.2.1.1` Auto-assign ticket to available technician based on skill and location
  - `ST.Y1.2.1.2` Send assignment notification to technician's mobile app
- *T.Y1.2.2 — Track Progress*
  - `ST.Y1.2.2.1` Technician updates status (Accepted, In Progress, On Hold, Resolved)
  - `ST.Y1.2.2.2` Log time spent, parts used, and resolution notes with before-after photos

### Y2 — Preventive Maintenance (4 sub-tasks)

**F.Y2.1 — Schedule PM Tasks**
- *T.Y2.1.1 — Define PM Checklist*
  - `ST.Y2.1.1.1` Create checklist for assets (Generator service, Fire extinguisher check, AC filter cleaning)
  - `ST.Y2.1.1.2` Set recurrence (Weekly, Monthly, Quarterly, Yearly)
- *T.Y2.1.2 — Generate PM Work Orders*
  - `ST.Y2.1.2.1` System auto-generates work orders based on schedule
  - `ST.Y2.1.2.2` Assign work orders and track completion to maintain asset health


## Module Z — Parent Portal & Mobile App (24 sub-tasks)

### Z1 — Unified Parent Dashboard (4 sub-tasks)

**F.Z1.1 — Child Overview**
- *T.Z1.1.1 — Display Child Summary*
  - `ST.Z1.1.1.1` Show all children with photos, classes, sections in single view
  - `ST.Z1.1.1.2` Show today's timetable, next class, and current location (if transport enabled)
- *T.Z1.1.2 — Academic Snapshot*
  - `ST.Z1.1.2.1` Display recent attendance %, last test scores, pending homework
  - `ST.Z1.1.2.2` Show fee dues summary and upcoming payment deadlines

### Z2 — Real-Time Notifications (4 sub-tasks)

**F.Z2.1 — Smart Alerts**
- *T.Z2.1.1 — Configure Alert Preferences*
  - `ST.Z2.1.1.1` Parent chooses notification types (Fee Reminders, Absence Alerts, Exam Results)
  - `ST.Z2.1.1.2` Set quiet hours to mute non-urgent notifications
- *T.Z2.1.2 — Push Notification Delivery*
  - `ST.Z2.1.2.1` Ensure reliable delivery via FCM (Android) and APNs (iOS)
  - `ST.Z2.1.2.2` Handle device token updates and notification preferences per device

### Z3 — In-App Communication (4 sub-tasks)

**F.Z3.1 — Teacher Messaging**
- *T.Z3.1.1 — Send Message to Teacher*
  - `ST.Z3.1.1.1` Select teacher from child's subject list and compose message
  - `ST.Z3.1.1.2` Attach files (photos, documents) and track read receipts
- *T.Z3.1.2 — Message History & Search*
  - `ST.Z3.1.2.1` View complete message history with any teacher
  - `ST.Z3.1.2.2` Search messages by keyword, teacher, or date range

### Z4 — Fee Management (4 sub-tasks)

**F.Z4.1 — Online Payments**
- *T.Z4.1.1 — Pay Fee Online*
  - `ST.Z4.1.1.1` View detailed fee breakdown and select specific installments to pay
  - `ST.Z4.1.1.2` Choose payment method (Credit/Debit Card, Net Banking, UPI, Wallet)
- *T.Z4.1.2 — Payment History & Receipts*
  - `ST.Z4.1.2.1` View all past transactions with status (Success, Failed, Pending)
  - `ST.Z4.1.2.2` Download and share payment receipts as PDF

### Z5 — Event & Volunteer Management (4 sub-tasks)

**F.Z5.1 — Event Participation**
- *T.Z5.1.1 — View School Events*
  - `ST.Z5.1.1.1` Browse calendar of upcoming events (PTM, Sports Day, Festivals)
  - `ST.Z5.1.1.2` RSVP for events and add to personal calendar
- *T.Z5.1.2 — Volunteer Sign-up*
  - `ST.Z5.1.2.1` Sign up for volunteer roles for events (e.g., Food stall, decoration)
  - `ST.Z5.1.2.2` Receive confirmation and reminders for assigned volunteer duties

### Z6 — Document Vault & Reports (4 sub-tasks)

**F.Z6.1 — Secure Document Access**
- *T.Z6.1.1 — Access Child Documents*
  - `ST.Z6.1.1.1` View and download report cards, mark sheets, certificates
  - `ST.Z6.1.1.2` Access medical records, vaccination certificates (with consent)
- *T.Z6.1.2 — Request Official Copies*
  - `ST.Z6.1.2.1` Submit online request for duplicate report cards or certificates
  - `ST.Z6.1.2.2` Track request status and pay any applicable fees online

---

*This document is auto-generated from `Feature_Status_v1_4.xlsx` + `PrimeAI_Master_Task_List.md`.*  
*Source: Prime-AI Platform RBS v1.4 — Menu-Aligned Edition*