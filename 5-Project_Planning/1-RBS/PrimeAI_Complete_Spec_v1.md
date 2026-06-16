# Prime-AI — Complete System Requirements & Work Item Specification

> **Project:** Prime-AI — Advanced AI-Powered School ERP, LMS & LXP Platform  
> **Organization:** PrimeGurukul  
> **Architecture:** Multi-Tenant SaaS (tenant_db / global_db pattern)  
> **Tech Stack:** PHP / Laravel (backend), MySQL (database), Vue.js / Blade (frontend), REST APIs  
> **Deployment:** Cloud (AWS / GCP), Docker containers, CI/CD  
> **Compliance:** NEP 2020, CBSE / ICSE / IB / Cambridge board patterns, GDPR / Data Privacy  
> **Document Purpose:** Complete specification for Claude AI Agent (VS Code) to generate SRS, DB Schema, APIs, Laravel code, test cases, screen/report/dashboard designs, and deployment plans  

---

## 1. Project Overview

### 1.1 Platform Summary

Prime-AI is a comprehensive, AI-powered, multi-tenant School Management Platform covering:

| Layer | Description |
|---|---|
| **ERP (School ERP)** | Admissions, SIS, Attendance, Timetable, Academics, Exams, Fees, Accounting, Inventory, Library, Transport, Hostel, HR, Communication, Certificates |
| **LMS** | Courses, Content, Assessments, Question Bank, Progress Tracking, Adaptive Learning |
| **LXP** | Personalized Learning Paths, Skill Graphs, AI Recommendations, Gamification, Social Learning |
| **ML/Analytics** | Predictive models for student risk, fee default, attendance, skill gap, route optimization |
| **SaaS Management** | Multi-tenant provisioning, subscription billing, metering, payment gateways |

### 1.2 Application Types

| App | Code Prefix | Description |
|---|---|---|
| **Prime App** | A, V, SYS | PrimeGurukul admin portal — manages tenants, subscriptions, billing, system health |
| **Tenant App** | B–Z (except V, SYS) | School-facing portal — all ERP/LMS/LXP functionality for each school tenant |
| **Parent/Mobile App** | Z | Parent-facing mobile application |

### 1.3 Architecture Principles

```
┌─────────────────────────────────────────────────────────────────┐
│                     Prime App (Admin Portal)                    │
│   Tenant Management │ Billing │ System Config │ Health Monitor  │
└───────────────────────────────┬─────────────────────────────────┘
                                │
              ┌─────────────────▼──────────────────┐
              │         global_db (shared)          │
              │  tenants │ plans │ menus │ modules  │
              └─────────────────┬──────────────────┘
                    ┌───────────┴────────────┐
            ┌───────▼───────┐       ┌────────▼──────┐
            │  tenant_db_1  │  ...  │  tenant_db_N  │
            │ (School A)    │       │ (School N)    │
            └───────────────┘       └───────────────┘
```

- Each school (tenant) has its own isolated database (`tenant_db`).
- Global data (plans, menus, billing) lives in `global_db`.
- All APIs are tenant-aware via subdomain / header-based routing.
- Laravel multi-tenancy via `stancl/tenancy` package or custom middleware.

### 1.4 Coding Standards for This Project

| Area | Standard |
|---|---|
| Backend | Laravel 11+, PHP 8.2+, PSR-12 coding standard |
| DB Migrations | Laravel migrations, no raw SQL in code |
| API | RESTful JSON APIs, versioned (`/api/v1/`), sanctum auth |
| Models | Eloquent ORM, soft deletes on all master tables |
| Policies | Laravel Gates & Policies for all permission checks |
| Events | Laravel Events & Listeners for async operations |
| Queues | Laravel Queues (Redis) for emails, notifications, reports |
| Testing | PHPUnit + Pest for unit/feature, Laravel Dusk for browser |
| Frontend | Blade templates + Alpine.js OR Vue.js components |
| Naming | snake_case for DB, camelCase for PHP/JS variables |

### 1.5 Module Summary Table

| Code | Module Name | App Type | Sub-Modules | Status Summary |
|---|---|---|---|---|
| **A** | Tenant & System Management | Prime | 9 | Completed |
| **B** | User, Roles & Security | Both | 6 | Completed |
| **C** | Admissions & Student Lifecycle | Both | 7 | Completed, Pending |
| **D** | Front Office & Communication | Both | 4 | Completed, Pending |
| **E** | Student Information System (SIS) | Both | 5 | Completed |
| **F** | Attendance Management | Both | 5 | Completed, Pending |
| **G** | Advanced Timetable Management | Both | 9 | Completed, In-Progress, Pending |
| **H** | Academics Management | Both | 7 | Completed, In-Progress, Pending |
| **I** | Examination & Gradebook | Both | 10 | Completed, In-Progress |
| **J** | Fees & Finance Management | Both | 10 | Completed |
| **K** | Finance & Accounting | Both | 13 | Pending |
| **L** | Inventory & Stock Management | Both | 11 | Pending |
| **M** | Library Management | Both | 7 | Completed |
| **N** | Transport Management | Both | 8 | Completed |
| **O** | Hostel Management | Both | 8 | Completed, Pending |
| **P** | Human Resources & Staff Mgmt. | Both | 7 | Pending |
| **Q** | Communication & Messaging | Both | 7 | Completed |
| **R** | Certificates, Docs & Identity | Both | 7 | Completed, Pending |
| **S** | Learning Management System (LMS) | Both | 11 | Completed, Pending |
| **SYS** | System Administration | Prime | 3 | Not Started |
| **T** | Learner Experience Platform (LXP) | Both | 9 | Not Started |
| **U** | Predictive Analytics & ML Engine | Both | 9 | Not Started |
| **V** | Multi-Tenant Billing & SaaS | Prime | 7 | Completed |
| **W** | Cafeteria & Mess Management | Both | 3 | Not Started |
| **X** | Visitor & Security Management | Both | 3 | Not Started |
| **Y** | Maintenance & Facility Helpdesk | Both | 2 | Not Started |
| **Z** | Parent Portal & Mobile App | Both | 6 | Not Started |

---

## 2. Database Design Principles

### 2.1 Global DB Tables (shared across all tenants)

```sql
-- Core global tables
tenants              -- tenant registry (id, name, subdomain, db_name, status)
subscription_plans   -- plan definitions (features, limits, pricing)
tenant_subscriptions -- which tenant is on which plan
invoices             -- billing records
payments             -- payment transactions
menus                -- prime app menu structure
modules              -- module registry for feature toggles
global_settings      -- platform-level config
audit_log_global     -- prime-level audit events
```

### 2.2 Tenant DB Tables (per-school database)

```sql
-- Every tenant DB has these tables (prefixed with tenant context)
-- All tables include: id, created_at, updated_at, deleted_at (soft delete)

-- Auth & Users
users               -- all user accounts (staff/student/parent)
roles               -- role definitions
permissions         -- permission definitions
role_has_permissions
user_has_roles

-- School Config
school_profile       -- school master
academic_sessions    -- session/year
boards               -- CBSE/ICSE/IB etc.
classes              -- class/grade
sections             -- section per class
subjects             -- subject master
class_subjects       -- subject-class mapping

-- Students
students             -- student master
student_addresses
student_documents
student_health_records
guardians            -- parent/guardian

-- And per-module tables as defined in each module section below
```

### 2.3 Universal Column Conventions

```sql
id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
created_by      BIGINT UNSIGNED NULL,   -- FK to users.id
updated_by      BIGINT UNSIGNED NULL,
created_at      TIMESTAMP NULL,
updated_at      TIMESTAMP NULL,
deleted_at      TIMESTAMP NULL          -- soft delete
```

---

## 3. Module Specifications

> Each module section contains: Overview, Sub-Modules, Feature Breakdown (Functionality → Task → Sub-Tasks), DB Tables, API Endpoints, Screen/Report/Dashboard requirements, and Test Case hints.

---

## Module A: Tenant & System Management

| | |
|---|---|
| **Module Code** | `A` |
| **App Type** | Prime |
| **Description** | Core SaaS platform admin — tenant provisioning, billing, auth, users, roles, audit, notifications. |
| **Total Sub-Modules** | 9 |
| **Total Features (Tasks)** | 24 |
| **Total Sub-Tasks** | 51 |

### Sub-Module Status

| Sub-Mod Code | Sub-Module Name | App Type | Status |
|---|---|---|---|
| `A1` | Tenant Registration & Onboarding | Prime | ✅ Completed 100% |
| `A2` | Tenant Feature Management | Prime | ✅ Completed 100% |
| `A3` | Authentication & Access Control | Prime | ✅ Completed 100% |
| `A4` | User Management | Prime | ✅ Completed 100% |
| `A5` | Role & Permission Management | Prime | ✅ Completed 100% |
| `A6` | Audit Logs & Monitoring | Prime | ✅ Completed 100% |
| `A7` | Notification & Communication Settings | Prime | ✅ Completed 100% |
| `A8` | Data Privacy & Compliance | Prime | ⬜ Not Started |
| `A9` | System Backup & Recovery | Prime | ⬜ Not Started |

### A1: Tenant Registration & Onboarding

**Status:** ✅ Completed 100%

#### `F.A1.1` — Tenant Creation

##### `T.A1.1.1` — Create Tenant

**Sub-Tasks:**

- `ST.A1.1.1.1` Enter school/organization name
- `ST.A1.1.1.2` Assign tenant code
- `ST.A1.1.1.3` Capture contact & address details
- `ST.A1.1.1.4` Upload logo and branding

##### `T.A1.1.2` — Configure Default Settings

**Sub-Tasks:**

- `ST.A1.1.2.1` Set academic year
- `ST.A1.1.2.2` Select default country/state/timezone

#### `F.A1.2` — Subscription Assignment

##### `T.A1.2.1` — Choose Plan

**Sub-Tasks:**

- `ST.A1.2.1.1` Select subscription plan
- `ST.A1.2.1.2` Attach modules enabled in plan

##### `T.A1.2.2` — Billing Cycle Setup

**Sub-Tasks:**

- `ST.A1.2.2.1` Define billing cycle (Monthly/Yearly)
- `ST.A1.2.2.2` Set next billing date

**Suggested DB Tables for `A1` — Tenant Registration & Onboarding:**

- `tenants`
- `tenant_onboarding_logs`
- `tenant_settings`

**Key API Endpoints for `A1`:**

```
GET    /api/v1/tenant-creation           # List / index
POST   /api/v1/tenant-creation           # Create
GET    /api/v1/tenant-creation/{id}    # Show
PUT    /api/v1/tenant-creation/{id}    # Update
DELETE /api/v1/tenant-creation/{id}    # Delete
GET    /api/v1/subscription-assignment           # List / index
POST   /api/v1/subscription-assignment           # Create
GET    /api/v1/subscription-assignment/{id}    # Show
PUT    /api/v1/subscription-assignment/{id}    # Update
DELETE /api/v1/subscription-assignment/{id}    # Delete
```

### A2: Tenant Feature Management

**Status:** ✅ Completed 100%

#### `F.A2.1` — Feature Toggles

##### `T.A2.1.1` — Enable/Disable Modules

**Sub-Tasks:**

- `ST.A2.1.1.1` Turn ON/OFF module access
- `ST.A2.1.1.2` Auto-update user access

##### `T.A2.1.2` — Advanced Feature Flags

**Sub-Tasks:**

- `ST.A2.1.2.1` Enable premium analytics
- `ST.A2.1.2.2` Enable AI-based recommendations

**Suggested DB Tables for `A2` — Tenant Feature Management:**

- `tenant_features`
- `feature_flags`

**Key API Endpoints for `A2`:**

```
GET    /api/v1/feature-toggles           # List / index
POST   /api/v1/feature-toggles           # Create
GET    /api/v1/feature-toggles/{id}    # Show
PUT    /api/v1/feature-toggles/{id}    # Update
DELETE /api/v1/feature-toggles/{id}    # Delete
```

### A3: Authentication & Access Control

**Status:** ✅ Completed 100%

#### `F.A3.1` — Login & Password Policies

##### `T.A3.1.1` — Password Rules

**Sub-Tasks:**

- `ST.A3.1.1.1` Set password strength
- `ST.A3.1.1.2` Set expiry days

##### `T.A3.1.2` — Multi-Factor Authentication

**Sub-Tasks:**

- `ST.A3.1.2.1` Enable OTP login
- `ST.A3.1.2.2` Enable authenticator app

#### `F.A3.2` — Single Sign-On

##### `T.A3.2.1` — SSO Setup

**Sub-Tasks:**

- `ST.A3.2.1.1` Configure OAuth provider
- `ST.A3.2.1.2` Map user identities

**Suggested DB Tables for `A3` — Authentication & Access Control:**

- `auth_policies`
- `login_attempts`
- `sso_configurations`

**Key API Endpoints for `A3`:**

```
GET    /api/v1/login---password-policies           # List / index
POST   /api/v1/login---password-policies           # Create
GET    /api/v1/login---password-policies/{id}    # Show
PUT    /api/v1/login---password-policies/{id}    # Update
DELETE /api/v1/login---password-policies/{id}    # Delete
GET    /api/v1/single-sign-on           # List / index
POST   /api/v1/single-sign-on           # Create
GET    /api/v1/single-sign-on/{id}    # Show
PUT    /api/v1/single-sign-on/{id}    # Update
DELETE /api/v1/single-sign-on/{id}    # Delete
```

### A4: User Management

**Status:** ✅ Completed 100%

#### `F.A4.1` — User Profiles

##### `T.A4.1.1` — Create User

**Sub-Tasks:**

- `ST.A4.1.1.1` Enter user details
- `ST.A4.1.1.2` Assign role
- `ST.A4.1.1.3` Send invite email

##### `T.A4.1.2` — Edit User

**Sub-Tasks:**

- `ST.A4.1.2.1` Modify profile details
- `ST.A4.1.2.2` Update contact information

#### `F.A4.2` — User Deactivation

##### `T.A4.2.1` — Disable User

**Sub-Tasks:**

- `ST.A4.2.1.1` Deactivate login access
- `ST.A4.2.1.2` Retain historical data

**Suggested DB Tables for `A4` — User Management:**

- `users`
- `user_profiles`
- `user_addresses`

**Key API Endpoints for `A4`:**

```
GET    /api/v1/user-profiles           # List / index
POST   /api/v1/user-profiles           # Create
GET    /api/v1/user-profiles/{id}    # Show
PUT    /api/v1/user-profiles/{id}    # Update
DELETE /api/v1/user-profiles/{id}    # Delete
GET    /api/v1/user-deactivation           # List / index
POST   /api/v1/user-deactivation           # Create
GET    /api/v1/user-deactivation/{id}    # Show
PUT    /api/v1/user-deactivation/{id}    # Update
DELETE /api/v1/user-deactivation/{id}    # Delete
```

### A5: Role & Permission Management

**Status:** ✅ Completed 100%

#### `F.A5.1` — Role Configuration

##### `T.A5.1.1` — Create Role

**Sub-Tasks:**

- `ST.A5.1.1.1` Name the role
- `ST.A5.1.1.2` Assign module permissions

##### `T.A5.1.2` — Clone Role

**Sub-Tasks:**

- `ST.A5.1.2.1` Duplicate an existing role
- `ST.A5.1.2.2` Customize permissions

#### `F.A5.2` — Permission Assignment

##### `T.A5.2.1` — Assign Permissions

**Sub-Tasks:**

- `ST.A5.2.1.1` Select CRUD rights
- `ST.A5.2.1.2` Apply permission to user groups

**Suggested DB Tables for `A5` — Role & Permission Management:**

- `roles`
- `permissions`
- `role_has_permissions`
- `user_has_roles`

**Key API Endpoints for `A5`:**

```
GET    /api/v1/role-configuration           # List / index
POST   /api/v1/role-configuration           # Create
GET    /api/v1/role-configuration/{id}    # Show
PUT    /api/v1/role-configuration/{id}    # Update
DELETE /api/v1/role-configuration/{id}    # Delete
GET    /api/v1/permission-assignment           # List / index
POST   /api/v1/permission-assignment           # Create
GET    /api/v1/permission-assignment/{id}    # Show
PUT    /api/v1/permission-assignment/{id}    # Update
DELETE /api/v1/permission-assignment/{id}    # Delete
```

### A6: Audit Logs & Monitoring

**Status:** ✅ Completed 100%

#### `F.A6.1` — System Logs

##### `T.A6.1.1` — Track Activities

**Sub-Tasks:**

- `ST.A6.1.1.1` Log user login/logout
- `ST.A6.1.1.2` Log data changes

##### `T.A6.1.2` — Export Logs

**Sub-Tasks:**

- `ST.A6.1.2.1` Download audit logs CSV
- `ST.A6.1.2.2` Filter logs by user/date

**Suggested DB Tables for `A6` — Audit Logs & Monitoring:**

- `audit_logs`
- `system_events`

**Key API Endpoints for `A6`:**

```
GET    /api/v1/system-logs           # List / index
POST   /api/v1/system-logs           # Create
GET    /api/v1/system-logs/{id}    # Show
PUT    /api/v1/system-logs/{id}    # Update
DELETE /api/v1/system-logs/{id}    # Delete
```

### A7: Notification & Communication Settings

**Status:** ✅ Completed 100%

#### `F.A7.1` — Notifications

##### `T.A7.1.1` — Email Settings

**Sub-Tasks:**

- `ST.A7.1.1.1` Configure SMTP
- `ST.A7.1.1.2` Set sender signature

##### `T.A7.1.2` — SMS Settings

**Sub-Tasks:**

- `ST.A7.1.2.1` Add SMS provider API key
- `ST.A7.1.2.2` Enable template approval

**Suggested DB Tables for `A7` — Notification & Communication Settings:**

- `notification_settings`
- `smtp_configs`
- `sms_gateway_configs`

**Key API Endpoints for `A7`:**

```
GET    /api/v1/notifications           # List / index
POST   /api/v1/notifications           # Create
GET    /api/v1/notifications/{id}    # Show
PUT    /api/v1/notifications/{id}    # Update
DELETE /api/v1/notifications/{id}    # Delete
```

### A8: Data Privacy & Compliance

**Status:** ⬜ Not Started

#### `F.A8.1` — GDPR/Data Protection

##### `T.A8.1.1` — Consent Management

**Sub-Tasks:**

- `ST.A8.1.1.1` Configure consent categories (Marketing, Data Sharing)
- `ST.A8.1.1.2` Record consent timestamps and versions

##### `T.A8.1.2` — Right to be Forgotten

**Sub-Tasks:**

- `ST.A8.1.2.1` Process data deletion requests
- `ST.A8.1.2.2` Anonymize vs. delete data based on retention rules

#### `F.A8.2` — Data Retention Policies

##### `T.A8.2.1` — Define Retention Rules

**Sub-Tasks:**

- `ST.A8.2.1.1` Set archival periods for student records post-graduation
- `ST.A8.2.1.2` Configure automated data purging schedules

**Suggested DB Tables for `A8` — Data Privacy & Compliance:**

- `pf_esi_configs`
- `statutory_reports`

**Key API Endpoints for `A8`:**

```
GET    /api/v1/gdpr-data-protection           # List / index
POST   /api/v1/gdpr-data-protection           # Create
GET    /api/v1/gdpr-data-protection/{id}    # Show
PUT    /api/v1/gdpr-data-protection/{id}    # Update
DELETE /api/v1/gdpr-data-protection/{id}    # Delete
GET    /api/v1/data-retention-policies           # List / index
POST   /api/v1/data-retention-policies           # Create
GET    /api/v1/data-retention-policies/{id}    # Show
PUT    /api/v1/data-retention-policies/{id}    # Update
DELETE /api/v1/data-retention-policies/{id}    # Delete
```

### A9: System Backup & Recovery

**Status:** ⬜ Not Started

#### `F.A9.1` — Backup Configuration

##### `T.A9.1.1` — Schedule Backups

**Sub-Tasks:**

- `ST.A9.1.1.1` Set daily/weekly backup frequency
- `ST.A9.1.1.2` Configure backup storage (Local/AWS S3/Google Cloud)

#### `F.A9.2` — Disaster Recovery

##### `T.A9.2.1` — Recovery Procedures

**Sub-Tasks:**

- `ST.A9.2.1.1` Define RTO (Recovery Time Objective) and RPO (Recovery Point Objective)
- `ST.A9.2.1.2` Create step-by-step recovery playbook for IT team

**Suggested DB Tables for `A9` — System Backup & Recovery:**

- `system_backup_recovery_master`
- `system_backup_recovery_transactions`
- `system_backup_recovery_logs`

**Key API Endpoints for `A9`:**

```
GET    /api/v1/backup-configuration           # List / index
POST   /api/v1/backup-configuration           # Create
GET    /api/v1/backup-configuration/{id}    # Show
PUT    /api/v1/backup-configuration/{id}    # Update
DELETE /api/v1/backup-configuration/{id}    # Delete
GET    /api/v1/disaster-recovery           # List / index
POST   /api/v1/disaster-recovery           # Create
GET    /api/v1/disaster-recovery/{id}    # Show
PUT    /api/v1/disaster-recovery/{id}    # Update
DELETE /api/v1/disaster-recovery/{id}    # Delete
```

### Screen Design Requirements — Module A

- **Tenant Creation** screen: List view with filters, Create/Edit form, Detail view with action buttons
- **Subscription Assignment** screen: List view with filters, Create/Edit form, Detail view with action buttons
- **Feature Selection** screen: List view with filters, Create/Edit form, Detail view with action buttons
- **Login Policies** screen: List view with filters, Create/Edit form, Detail view with action buttons
- **Tenant User Creation** screen: List view with filters, Create/Edit form, Detail view with action buttons
- **Tenant Role Creation** screen: List view with filters, Create/Edit form, Detail view with action buttons
- **Assign Module Permission** screen: List view with filters, Create/Edit form, Detail view with action buttons
- **Role Cloning** screen: List view with filters, Create/Edit form, Detail view with action buttons
- **Permission Assignment** screen: List view with filters, Create/Edit form, Detail view with action buttons
- **Email Settings** screen: List view with filters, Create/Edit form, Detail view with action buttons
- **SMS Settings** screen: List view with filters, Create/Edit form, Detail view with action buttons

### Report Requirements — Module A

- **Login & Password Policies**: Tabular report with date range filter, export to PDF/Excel/CSV
- **System Logs**: Tabular report with date range filter, export to PDF/Excel/CSV

### Test Case Requirements — Module A

| Test Type | Scope |
|---|---|
| **Unit Tests** | All service classes and model methods in Module A |
| **Feature Tests** | All API endpoints — happy path, validation errors, auth failures |
| **Browser Tests** | Form submissions, list pagination, filter/search, export |
| **Functional Tests** | End-to-end business workflows (e.g., create → approve → complete lifecycle) |

---

## Module B: User, Roles & Security

| | |
|---|---|
| **Module Code** | `B` |
| **App Type** | Both |
| **Description** | School-level user profiles, role creation, permission management, MFA, session control, audit logs. |
| **Total Sub-Modules** | 6 |
| **Total Features (Tasks)** | 22 |
| **Total Sub-Tasks** | 52 |

### Sub-Module Status

| Sub-Mod Code | Sub-Module Name | App Type | Status |
|---|---|---|---|
| `B1` | User Profile Management | Both | ✅ Completed 100% |
| `B2` | Role Management | Both | ✅ Completed 100% |
| `B3` | Permission Management | Both | ✅ Completed 100% |
| `B4` | Authentication & Security Policies | Both | ✅ Completed 100% |
| `B5` | Session & Device Management | Both | ✅ Completed 100% |
| `B6` | Audit Logging & Monitoring | Both | ✅ Completed 100% |

### B1: User Profile Management

**Status:** ✅ Completed 100%

#### `F.B1.1` — User Creation

##### `T.B1.1.1` — Create User Profile

**Sub-Tasks:**

- `ST.B1.1.1.1` Enter user details (name, email, phone)
- `ST.B1.1.1.2` Assign default role
- `ST.B1.1.1.3` Send activation email

##### `T.B1.1.2` — Bulk User Upload

**Sub-Tasks:**

- `ST.B1.1.2.1` Upload CSV of users
- `ST.B1.1.2.2` Map CSV columns to fields
- `ST.B1.1.2.3` Validate and import users

#### `F.B1.2` — User Profile Editing

##### `T.B1.2.1` — Edit User Details

**Sub-Tasks:**

- `ST.B1.2.1.1` Modify contact information
- `ST.B1.2.1.2` Update profile photo
- `ST.B1.2.1.3` Edit personal information

##### `T.B1.2.2` — User Status Management

**Sub-Tasks:**

- `ST.B1.2.2.1` Activate user
- `ST.B1.2.2.2` Deactivate user
- `ST.B1.2.2.3` Lock/Unlock account

**Suggested DB Tables for `B1` — User Profile Management:**

- `users`
- `user_profiles`
- `user_addresses`

**Key API Endpoints for `B1`:**

```
GET    /api/v1/user-creation           # List / index
POST   /api/v1/user-creation           # Create
GET    /api/v1/user-creation/{id}    # Show
PUT    /api/v1/user-creation/{id}    # Update
DELETE /api/v1/user-creation/{id}    # Delete
GET    /api/v1/user-profile-editing           # List / index
POST   /api/v1/user-profile-editing           # Create
GET    /api/v1/user-profile-editing/{id}    # Show
PUT    /api/v1/user-profile-editing/{id}    # Update
DELETE /api/v1/user-profile-editing/{id}    # Delete
```

### B2: Role Management

**Status:** ✅ Completed 100%

#### `F.B2.1` — Role Creation

##### `T.B2.1.1` — Create Role

**Sub-Tasks:**

- `ST.B2.1.1.1` Define role name
- `ST.B2.1.1.2` Add description
- `ST.B2.1.1.3` Select applicable modules

##### `T.B2.1.2` — Clone Role

**Sub-Tasks:**

- `ST.B2.1.2.1` Choose existing role
- `ST.B2.1.2.2` Duplicate permissions
- `ST.B2.1.2.3` Modify cloned role

#### `F.B2.2` — Role Assignment

##### `T.B2.2.1` — Assign Role to User

**Sub-Tasks:**

- `ST.B2.2.1.1` Select user
- `ST.B2.2.1.2` Select one or multiple roles
- `ST.B2.2.1.3` Apply assignment

**Suggested DB Tables for `B2` — Role Management:**

- `role_management_master`
- `role_management_transactions`
- `role_management_logs`

**Key API Endpoints for `B2`:**

```
GET    /api/v1/role-creation           # List / index
POST   /api/v1/role-creation           # Create
GET    /api/v1/role-creation/{id}    # Show
PUT    /api/v1/role-creation/{id}    # Update
DELETE /api/v1/role-creation/{id}    # Delete
GET    /api/v1/role-assignment           # List / index
POST   /api/v1/role-assignment           # Create
GET    /api/v1/role-assignment/{id}    # Show
PUT    /api/v1/role-assignment/{id}    # Update
DELETE /api/v1/role-assignment/{id}    # Delete
```

### B3: Permission Management

**Status:** ✅ Completed 100%

#### `F.B3.1` — Module Permissions

##### `T.B3.1.1` — Grant Module Access

**Sub-Tasks:**

- `ST.B3.1.1.1` Enable module visibility
- `ST.B3.1.1.2` Grant create/read/update/delete rights

##### `T.B3.1.2` — Restrict Functionality

**Sub-Tasks:**

- `ST.B3.1.2.1` Disable sensitive features
- `ST.B3.1.2.2` Restrict student/fee access

#### `F.B3.2` — Page-Level Permissions

##### `T.B3.2.1` — Fine-Grained Control

**Sub-Tasks:**

- `ST.B3.2.1.1` Enable page access (Tab/Component Level Access)
- `ST.B3.2.1.2` Disable page elements (Tab/Component Level Access)

##### `T.B3.2.2` — UI Element-Level Permissions

**Sub-Tasks:**

- `ST.B3.2.2.1` Control button visibility
- `ST.B3.2.2.2` Restrict action triggers

**Suggested DB Tables for `B3` — Permission Management:**

- `permission_management_master`
- `permission_management_transactions`
- `permission_management_logs`

**Key API Endpoints for `B3`:**

```
GET    /api/v1/module-permissions           # List / index
POST   /api/v1/module-permissions           # Create
GET    /api/v1/module-permissions/{id}    # Show
PUT    /api/v1/module-permissions/{id}    # Update
DELETE /api/v1/module-permissions/{id}    # Delete
GET    /api/v1/page-level-permissions           # List / index
POST   /api/v1/page-level-permissions           # Create
GET    /api/v1/page-level-permissions/{id}    # Show
PUT    /api/v1/page-level-permissions/{id}    # Update
DELETE /api/v1/page-level-permissions/{id}    # Delete
```

### B4: Authentication & Security Policies

**Status:** ✅ Completed 100%

#### `F.B4.1` — Authentication Rules

##### `T.B4.1.1` — Password Policies

**Sub-Tasks:**

- `ST.B4.1.1.1` Define password complexity
- `ST.B4.1.1.2` Set password expiration days
- `ST.B4.1.1.3` Force password reset

##### `T.B4.1.2` — Login Restrictions

**Sub-Tasks:**

- `ST.B4.1.2.1` Limit failed login attempts
- `ST.B4.1.2.2` Enable IP restrictions

#### `F.B4.2` — Multi-Factor Authentication

##### `T.B4.2.1` — MFA Setup

**Sub-Tasks:**

- `ST.B4.2.1.1` Enable OTP login
- `ST.B4.2.1.2` Setup authenticator app

**Suggested DB Tables for `B4` — Authentication & Security Policies:**

- `auth_policies`
- `login_attempts`
- `sso_configurations`

**Key API Endpoints for `B4`:**

```
GET    /api/v1/authentication-rules           # List / index
POST   /api/v1/authentication-rules           # Create
GET    /api/v1/authentication-rules/{id}    # Show
PUT    /api/v1/authentication-rules/{id}    # Update
DELETE /api/v1/authentication-rules/{id}    # Delete
GET    /api/v1/multi-factor-authentication           # List / index
POST   /api/v1/multi-factor-authentication           # Create
GET    /api/v1/multi-factor-authentication/{id}    # Show
PUT    /api/v1/multi-factor-authentication/{id}    # Update
DELETE /api/v1/multi-factor-authentication/{id}    # Delete
```

### B5: Session & Device Management

**Status:** ✅ Completed 100%

#### `F.B5.1` — Session Control

##### `T.B5.1.1` — Session Timeout

**Sub-Tasks:**

- `ST.B5.1.1.1` Set inactivity timeout
- `ST.B5.1.1.2` Auto-logout user

##### `T.B5.1.2` — Concurrent Session Limit

**Sub-Tasks:**

- `ST.B5.1.2.1` Restrict number of active sessions
- `ST.B5.1.2.2` Force login revocation

#### `F.B5.2` — Device Management

##### `T.B5.2.1` — Trusted Devices

**Sub-Tasks:**

- `ST.B5.2.1.1` Register new device
- `ST.B5.2.1.2` Review trusted devices

##### `T.B5.2.2` — Block Devices

**Sub-Tasks:**

- `ST.B5.2.2.1` Remove device from trusted list
- `ST.B5.2.2.2` Block future logins from device

**Suggested DB Tables for `B5` — Session & Device Management:**

- `session_device_management_master`
- `session_device_management_transactions`
- `session_device_management_logs`

**Key API Endpoints for `B5`:**

```
GET    /api/v1/session-control           # List / index
POST   /api/v1/session-control           # Create
GET    /api/v1/session-control/{id}    # Show
PUT    /api/v1/session-control/{id}    # Update
DELETE /api/v1/session-control/{id}    # Delete
GET    /api/v1/device-management           # List / index
POST   /api/v1/device-management           # Create
GET    /api/v1/device-management/{id}    # Show
PUT    /api/v1/device-management/{id}    # Update
DELETE /api/v1/device-management/{id}    # Delete
```

### B6: Audit Logging & Monitoring

**Status:** ✅ Completed 100%

#### `F.B6.1` — User Activity Logs

##### `T.B6.1.1` — Login/Logout Tracking

**Sub-Tasks:**

- `ST.B6.1.1.1` Record login timestamp
- `ST.B6.1.1.2` Track logout or session timeout

##### `T.B6.1.2` — Operation Logs

**Sub-Tasks:**

- `ST.B6.1.2.1` Log add/update/delete actions
- `ST.B6.1.2.2` Store before/after values

#### `F.B6.2` — Security Audit

##### `T.B6.2.1` — Suspicious Activity Detection

**Sub-Tasks:**

- `ST.B6.2.1.1` Flag repeated failed logins
- `ST.B6.2.1.2` Detect abnormal access patterns

##### `T.B6.2.2` — Audit Log Export

**Sub-Tasks:**

- `ST.B6.2.2.1` Download logs CSV
- `ST.B6.2.2.2` Filter logs by date/user/module

**Suggested DB Tables for `B6` — Audit Logging & Monitoring:**

- `audit_logs`
- `system_events`

**Key API Endpoints for `B6`:**

```
GET    /api/v1/user-activity-logs           # List / index
POST   /api/v1/user-activity-logs           # Create
GET    /api/v1/user-activity-logs/{id}    # Show
PUT    /api/v1/user-activity-logs/{id}    # Update
DELETE /api/v1/user-activity-logs/{id}    # Delete
GET    /api/v1/security-audit           # List / index
POST   /api/v1/security-audit           # Create
GET    /api/v1/security-audit/{id}    # Show
PUT    /api/v1/security-audit/{id}    # Update
DELETE /api/v1/security-audit/{id}    # Delete
```

### Screen Design Requirements — Module B

- **User Creation** screen: List view with filters, Create/Edit form, Detail view with action buttons
- **User Profile Editing** screen: List view with filters, Create/Edit form, Detail view with action buttons
- **Role Creation** screen: List view with filters, Create/Edit form, Detail view with action buttons
- **Password Policy** screen: List view with filters, Create/Edit form, Detail view with action buttons
- **Security Policy** screen: List view with filters, Create/Edit form, Detail view with action buttons
- **Multi-Factor Authentication** screen: List view with filters, Create/Edit form, Detail view with action buttons
- **Session Control** screen: List view with filters, Create/Edit form, Detail view with action buttons
- **Device Management** screen: List view with filters, Create/Edit form, Detail view with action buttons
- **User Activity Logs** screen: List view with filters, Create/Edit form, Detail view with action buttons
- **Security Audit** screen: List view with filters, Create/Edit form, Detail view with action buttons

### Report Requirements — Module B

- **User Activity Logs**: Tabular report with date range filter, export to PDF/Excel/CSV

### Test Case Requirements — Module B

| Test Type | Scope |
|---|---|
| **Unit Tests** | All service classes and model methods in Module B |
| **Feature Tests** | All API endpoints — happy path, validation errors, auth failures |
| **Browser Tests** | Form submissions, list pagination, filter/search, export |
| **Functional Tests** | End-to-end business workflows (e.g., create → approve → complete lifecycle) |

---

## Module C: Admissions & Student Lifecycle

| | |
|---|---|
| **Module Code** | `C` |
| **App Type** | Both |
| **Description** | End-to-end admission funnel — leads, applications, offers, enrollment, student profiles, promotions. |
| **Total Sub-Modules** | 7 |
| **Total Features (Tasks)** | 27 |
| **Total Sub-Tasks** | 56 |

### Sub-Module Status

| Sub-Mod Code | Sub-Module Name | App Type | Status |
|---|---|---|---|
| `C1` | Enquiry & Lead Management | Both | ⬜ Pending |
| `C2` | Application Management | Both | ⬜ Pending |
| `C3` | Admission Management | Both | ✅ Completed 100% |
| `C4` | Student Profile & Record Management | Both | ✅ Completed 100% |
| `C5` | Student Promotion & Alumni | Both | ⬜ Pending |
| `C6` | Multi-Curriculum & Syllabus Manager | Both | ⬜ Not Started |
| `C7` | Disciplinary & Behavior Tracking | Both | ⬜ Not Started |

### C1: Enquiry & Lead Management

**Status:** ⬜ Pending

#### `F.C1.1` — Lead Capture

##### `T.C1.1.1` — Record Enquiry

**Sub-Tasks:**

- `ST.C1.1.1.1` Capture student & parent contact details
- `ST.C1.1.1.2` Select academic year & class sought
- `ST.C1.1.1.3` Assign lead source (Website, Walk-in, Campaign)

##### `T.C1.1.2` — Lead Assignment

**Sub-Tasks:**

- `ST.C1.1.2.1` Assign counselor
- `ST.C1.1.2.2` Auto-assign based on availability

#### `F.C1.2` — Lead Follow-up

##### `T.C1.2.1` — Follow-up Scheduling

**Sub-Tasks:**

- `ST.C1.2.1.1` Schedule call/meeting
- `ST.C1.2.1.2` Set follow-up reminder

##### `T.C1.2.2` — Lead Status Tracking

**Sub-Tasks:**

- `ST.C1.2.2.1` Mark as Interested/Not Interested
- `ST.C1.2.2.2` Convert to Application

**Suggested DB Tables for `C1` — Enquiry & Lead Management:**

- `admission_enquiries`
- `lead_follow_ups`
- `lead_sources`

**Key API Endpoints for `C1`:**

```
GET    /api/v1/lead-capture           # List / index
POST   /api/v1/lead-capture           # Create
GET    /api/v1/lead-capture/{id}    # Show
PUT    /api/v1/lead-capture/{id}    # Update
DELETE /api/v1/lead-capture/{id}    # Delete
GET    /api/v1/lead-follow-up           # List / index
POST   /api/v1/lead-follow-up           # Create
GET    /api/v1/lead-follow-up/{id}    # Show
PUT    /api/v1/lead-follow-up/{id}    # Update
DELETE /api/v1/lead-follow-up/{id}    # Delete
```

### C2: Application Management

**Status:** ⬜ Pending

#### `F.C2.1` — Application Form

##### `T.C2.1.1` — Create Application

**Sub-Tasks:**

- `ST.C2.1.1.1` Fill student details
- `ST.C2.1.1.2` Fill parent/guardian info
- `ST.C2.1.1.3` Upload documents

##### `T.C2.1.2` — Application Fees

**Sub-Tasks:**

- `ST.C2.1.2.1` Generate application fee challan
- `ST.C2.1.2.2` Verify fee payment

#### `F.C2.2` — Application Processing

##### `T.C2.2.1` — Verification

**Sub-Tasks:**

- `ST.C2.2.1.1` Verify uploaded documents
- `ST.C2.2.1.2` Approve/Reject application

##### `T.C2.2.2` — Interview Scheduling

**Sub-Tasks:**

- `ST.C2.2.2.1` Schedule interview slot
- `ST.C2.2.2.2` Notify parents via SMS/Email

**Suggested DB Tables for `C2` — Application Management:**

- `admission_applications`
- `application_fees`
- `application_documents`

**Key API Endpoints for `C2`:**

```
GET    /api/v1/application-form           # List / index
POST   /api/v1/application-form           # Create
GET    /api/v1/application-form/{id}    # Show
PUT    /api/v1/application-form/{id}    # Update
DELETE /api/v1/application-form/{id}    # Delete
GET    /api/v1/application-processing           # List / index
POST   /api/v1/application-processing           # Create
GET    /api/v1/application-processing/{id}    # Show
PUT    /api/v1/application-processing/{id}    # Update
DELETE /api/v1/application-processing/{id}    # Delete
```

### C3: Admission Management

**Status:** ✅ Completed 100%

#### `F.C3.1` — Admission Offer

##### `T.C3.1.1` — Generate Offer Letter

**Sub-Tasks:**

- `ST.C3.1.1.1` Assign admission number
- `ST.C3.1.1.2` Set joining date

##### `T.C3.1.2` — Admission Fee Collection

**Sub-Tasks:**

- `ST.C3.1.2.1` Generate admission fee invoice
- `ST.C3.1.2.2` Confirm payment

#### `F.C3.2` — Finalize Admission

##### `T.C3.2.1` — Complete Enrollment

**Sub-Tasks:**

- `ST.C3.2.1.1` Assign class/section
- `ST.C3.2.1.2` Generate student ID card

##### `T.C3.2.2` — Document Submission

**Sub-Tasks:**

- `ST.C3.2.2.1` Collect physical documents
- `ST.C3.2.2.2` Update mandatory fields

**Suggested DB Tables for `C3` — Admission Management:**

- `admission_enquiries`
- `lead_follow_ups`
- `lead_sources`

**Key API Endpoints for `C3`:**

```
GET    /api/v1/admission-offer           # List / index
POST   /api/v1/admission-offer           # Create
GET    /api/v1/admission-offer/{id}    # Show
PUT    /api/v1/admission-offer/{id}    # Update
DELETE /api/v1/admission-offer/{id}    # Delete
GET    /api/v1/finalize-admission           # List / index
POST   /api/v1/finalize-admission           # Create
GET    /api/v1/finalize-admission/{id}    # Show
PUT    /api/v1/finalize-admission/{id}    # Update
DELETE /api/v1/finalize-admission/{id}    # Delete
```

### C4: Student Profile & Record Management

**Status:** ✅ Completed 100%

#### `F.C4.1` — Student Profile

##### `T.C4.1.1` — Create Student Profile

**Sub-Tasks:**

- `ST.C4.1.1.1` Store personal details
- `ST.C4.1.1.2` Store address & emergency contacts

##### `T.C4.1.2` — Maintain Records

**Sub-Tasks:**

- `ST.C4.1.2.1` Track caste/category
- `ST.C4.1.2.2` Update health information

#### `F.C4.2` — Student Documents

##### `T.C4.2.1` — Upload Documents

**Sub-Tasks:**

- `ST.C4.2.1.1` Upload TC/Marksheets
- `ST.C4.2.1.2` Upload medical certificate

##### `T.C4.2.2` — Document Verification

**Sub-Tasks:**

- `ST.C4.2.2.1` Approve authenticity
- `ST.C4.2.2.2` Update verification status

**Suggested DB Tables for `C4` — Student Profile & Record Management:**

- `students`
- `student_documents`
- `student_addresses`
- `guardians`

**Key API Endpoints for `C4`:**

```
GET    /api/v1/student-profile           # List / index
POST   /api/v1/student-profile           # Create
GET    /api/v1/student-profile/{id}    # Show
PUT    /api/v1/student-profile/{id}    # Update
DELETE /api/v1/student-profile/{id}    # Delete
GET    /api/v1/student-documents           # List / index
POST   /api/v1/student-documents           # Create
GET    /api/v1/student-documents/{id}    # Show
PUT    /api/v1/student-documents/{id}    # Update
DELETE /api/v1/student-documents/{id}    # Delete
```

### C5: Student Promotion & Alumni

**Status:** ⬜ Pending

#### `F.C5.1` — Promotion Processing

##### `T.C5.1.1` — Generate Promotion List

**Sub-Tasks:**

- `ST.C5.1.1.1` Fetch eligible students
- `ST.C5.1.1.2` Apply promotion criteria

##### `T.C5.1.2` — Assign New Class

**Sub-Tasks:**

- `ST.C5.1.2.1` Bulk assign promoted class
- `ST.C5.1.2.2` Generate new session roll numbers

#### `F.C5.2` — Alumni Management

##### `T.C5.2.1` — Mark as Alumni

**Sub-Tasks:**

- `ST.C5.2.1.1` Move student to alumni list
- `ST.C5.2.1.2` Close active academic records

##### `T.C5.2.2` — Issue Transfer Certificate

**Sub-Tasks:**

- `ST.C5.2.2.1` Generate TC with details
- `ST.C5.2.2.2` Track TC issue history

**Suggested DB Tables for `C5` — Student Promotion & Alumni:**

- `student_promotions`
- `alumni_records`
- `transfer_certificates`

**Key API Endpoints for `C5`:**

```
GET    /api/v1/promotion-processing           # List / index
POST   /api/v1/promotion-processing           # Create
GET    /api/v1/promotion-processing/{id}    # Show
PUT    /api/v1/promotion-processing/{id}    # Update
DELETE /api/v1/promotion-processing/{id}    # Delete
GET    /api/v1/alumni-management           # List / index
POST   /api/v1/alumni-management           # Create
GET    /api/v1/alumni-management/{id}    # Show
PUT    /api/v1/alumni-management/{id}    # Update
DELETE /api/v1/alumni-management/{id}    # Delete
```

### C6: Multi-Curriculum & Syllabus Manager

**Status:** ⬜ Not Started

#### `F.C6.1` — Curriculum Configuration

##### `T.C6.1.1` — Add Board/Curriculum

**Sub-Tasks:**

- `ST.C6.1.1.1` Define board name (CBSE, ICSE, State Board, IB, Cambridge)
- `ST.C6.1.1.2` Set board-specific academic calendar patterns

##### `T.C6.1.2` — Map Subjects to Board

**Sub-Tasks:**

- `ST.C6.1.2.1` Link school subjects to board-specific subject codes
- `ST.C6.1.2.2` Define credit hours/weightage per board requirement

#### `F.C6.2` — Syllabus & Lesson Planning

##### `T.C6.2.1` — Create Syllabus Unit

**Sub-Tasks:**

- `ST.C6.2.1.1` Define units/chapters with start-end dates
- `ST.C6.2.1.2` Attach learning objectives and outcomes per unit

##### `T.C6.2.2` — Syllabus Progress Tracking

**Sub-Tasks:**

- `ST.C6.2.2.1` Track completion percentage vs. planned timeline
- `ST.C6.2.2.2` Generate alerts for syllabus lag

**Suggested DB Tables for `C6` — Multi-Curriculum & Syllabus Manager:**

- `curricula`
- `syllabus_units`
- `lesson_topics`
- `board_mappings`

**Key API Endpoints for `C6`:**

```
GET    /api/v1/curriculum-configuration           # List / index
POST   /api/v1/curriculum-configuration           # Create
GET    /api/v1/curriculum-configuration/{id}    # Show
PUT    /api/v1/curriculum-configuration/{id}    # Update
DELETE /api/v1/curriculum-configuration/{id}    # Delete
GET    /api/v1/syllabus---lesson-planning           # List / index
POST   /api/v1/syllabus---lesson-planning           # Create
GET    /api/v1/syllabus---lesson-planning/{id}    # Show
PUT    /api/v1/syllabus---lesson-planning/{id}    # Update
DELETE /api/v1/syllabus---lesson-planning/{id}    # Delete
```

### C7: Disciplinary & Behavior Tracking

**Status:** ⬜ Not Started

#### `F.C7.1` — Incident Management

##### `T.C7.1.1` — Record Disciplinary Incident

**Sub-Tasks:**

- `ST.C7.1.1.1` Log incident type (Bullying, Cheating, Disruption)
- `ST.C7.1.1.2` Assign severity level (Low, Medium, High, Critical)

##### `T.C7.1.2` — Action & Follow-up

**Sub-Tasks:**

- `ST.C7.1.2.1` Define corrective actions (Warning, Detention, Suspension)
- `ST.C7.1.2.2` Schedule parent meetings and log outcomes

#### `F.C7.2` — Behavior Analytics

##### `T.C7.2.1` — Generate Behavior Reports

**Sub-Tasks:**

- `ST.C7.2.1.1` Identify patterns (repeat offenders, time/day trends)
- `ST.C7.2.1.2` Track improvement over time with behavior scores

**Suggested DB Tables for `C7` — Disciplinary & Behavior Tracking:**

- `disciplinary_behavior_tracking_master`
- `disciplinary_behavior_tracking_transactions`
- `disciplinary_behavior_tracking_logs`

**Key API Endpoints for `C7`:**

```
GET    /api/v1/incident-management           # List / index
POST   /api/v1/incident-management           # Create
GET    /api/v1/incident-management/{id}    # Show
PUT    /api/v1/incident-management/{id}    # Update
DELETE /api/v1/incident-management/{id}    # Delete
GET    /api/v1/behavior-analytics           # List / index
POST   /api/v1/behavior-analytics           # Create
GET    /api/v1/behavior-analytics/{id}    # Show
PUT    /api/v1/behavior-analytics/{id}    # Update
DELETE /api/v1/behavior-analytics/{id}    # Delete
```

### Screen Design Requirements — Module C

- **Lead Capture** screen: List view with filters, Create/Edit form, Detail view with action buttons
- **Lead Follow-up** screen: List view with filters, Create/Edit form, Detail view with action buttons
- **Application Form** screen: List view with filters, Create/Edit form, Detail view with action buttons
- **Application Processing** screen: List view with filters, Create/Edit form, Detail view with action buttons
- **Admission Offer** screen: List view with filters, Create/Edit form, Detail view with action buttons
- **Finalize Admission** screen: List view with filters, Create/Edit form, Detail view with action buttons
- **Student Profile** screen: List view with filters, Create/Edit form, Detail view with action buttons
- **Student Documents** screen: List view with filters, Create/Edit form, Detail view with action buttons
- **Academic Session Mgmt.** screen: List view with filters, Create/Edit form, Detail view with action buttons

### Report Requirements — Module C

- **Behavior Analytics**: Tabular report with date range filter, export to PDF/Excel/CSV

### Test Case Requirements — Module C

| Test Type | Scope |
|---|---|
| **Unit Tests** | All service classes and model methods in Module C |
| **Feature Tests** | All API endpoints — happy path, validation errors, auth failures |
| **Browser Tests** | Form submissions, list pagination, filter/search, export |
| **Functional Tests** | End-to-end business workflows (e.g., create → approve → complete lifecycle) |

---

## Module D: Front Office & Communication

| | |
|---|---|
| **Module Code** | `D` |
| **App Type** | Both |
| **Description** | Reception desk, visitor management, gate passes, bulk communications, complaints, certificates. |
| **Total Sub-Modules** | 4 |
| **Total Features (Tasks)** | 15 |
| **Total Sub-Tasks** | 31 |

### Sub-Module Status

| Sub-Mod Code | Sub-Module Name | App Type | Status |
|---|---|---|---|
| `D1` | Front Office Desk Management | Both | ⬜ Pending |
| `D2` | Communication Management | Both | ⬜ Pending |
| `D3` | Complaint & Feedback Management | Both | ✅ Completed 100% |
| `D4` | Document & Certificate Issuance | Both | ⬜ Pending |

### D1: Front Office Desk Management

**Status:** ⬜ Pending

#### `F.D1.1` — Visitor Management

##### `T.D1.1.1` — Register Visitor

**Sub-Tasks:**

- `ST.D1.1.1.1` Capture visitor name & contact
- `ST.D1.1.1.2` Log purpose of visit
- `ST.D1.1.1.3` Capture in/out time

##### `T.D1.1.2` — Visitor Pass

**Sub-Tasks:**

- `ST.D1.1.2.1` Generate visitor pass
- `ST.D1.1.2.2` Print visitor slip

#### `F.D1.2` — Gate Pass

##### `T.D1.2.1` — Issue Gate Pass

**Sub-Tasks:**

- `ST.D1.2.1.1` Create gate pass for students/staff
- `ST.D1.2.1.2` Capture exit purpose

##### `T.D1.2.2` — Gate Pass Approval

**Sub-Tasks:**

- `ST.D1.2.2.1` Send approval request to authority
- `ST.D1.2.2.2` Record approval/rejection

**Suggested DB Tables for `D1` — Front Office Desk Management:**

- `front_office_desk_management_master`
- `front_office_desk_management_transactions`
- `front_office_desk_management_logs`

**Key API Endpoints for `D1`:**

```
GET    /api/v1/visitor-management           # List / index
POST   /api/v1/visitor-management           # Create
GET    /api/v1/visitor-management/{id}    # Show
PUT    /api/v1/visitor-management/{id}    # Update
DELETE /api/v1/visitor-management/{id}    # Delete
GET    /api/v1/gate-pass           # List / index
POST   /api/v1/gate-pass           # Create
GET    /api/v1/gate-pass/{id}    # Show
PUT    /api/v1/gate-pass/{id}    # Update
DELETE /api/v1/gate-pass/{id}    # Delete
```

### D2: Communication Management

**Status:** ⬜ Pending

#### `F.D2.1` — Email Communication

##### `T.D2.1.1` — Send Email

**Sub-Tasks:**

- `ST.D2.1.1.1` Select recipients (Students/Staff/Parents)
- `ST.D2.1.1.2` Attach documents

##### `T.D2.1.2` — Email Templates

**Sub-Tasks:**

- `ST.D2.1.2.1` Create email templates
- `ST.D2.1.2.2` Save templates for reuse

#### `F.D2.2` — SMS Communication

##### `T.D2.2.1` — Send SMS

**Sub-Tasks:**

- `ST.D2.2.1.1` Compose SMS message
- `ST.D2.2.1.2` Select recipients

##### `T.D2.2.2` — SMS Logs

**Sub-Tasks:**

- `ST.D2.2.2.1` Track delivery reports
- `ST.D2.2.2.2` Download SMS report

**Suggested DB Tables for `D2` — Communication Management:**

- `communication_logs`
- `email_templates`
- `sms_templates`
- `notification_logs`

**Key API Endpoints for `D2`:**

```
GET    /api/v1/email-communication           # List / index
POST   /api/v1/email-communication           # Create
GET    /api/v1/email-communication/{id}    # Show
PUT    /api/v1/email-communication/{id}    # Update
DELETE /api/v1/email-communication/{id}    # Delete
GET    /api/v1/sms-communication           # List / index
POST   /api/v1/sms-communication           # Create
GET    /api/v1/sms-communication/{id}    # Show
PUT    /api/v1/sms-communication/{id}    # Update
DELETE /api/v1/sms-communication/{id}    # Delete
```

### D3: Complaint & Feedback Management

**Status:** ✅ Completed 100%

#### `F.D3.1` — Complaint Handling

##### `T.D3.1.1` — Register Complaint

**Sub-Tasks:**

- `ST.D3.1.1.1` Enter complaint details
- `ST.D3.1.1.2` Assign complaint to staff

##### `T.D3.1.2` — Complaint Resolution

**Sub-Tasks:**

- `ST.D3.1.2.1` Update resolution status
- `ST.D3.1.2.2` Add resolution notes

#### `F.D3.2` — Feedback Collection

##### `T.D3.2.1` — Collect Feedback

**Sub-Tasks:**

- `ST.D3.2.1.1` Create feedback form
- `ST.D3.2.1.2` Collect responses

**Suggested DB Tables for `D3` — Complaint & Feedback Management:**

- `complaints`
- `complaint_resolutions`
- `feedback_forms`

**Key API Endpoints for `D3`:**

```
GET    /api/v1/complaint-handling           # List / index
POST   /api/v1/complaint-handling           # Create
GET    /api/v1/complaint-handling/{id}    # Show
PUT    /api/v1/complaint-handling/{id}    # Update
DELETE /api/v1/complaint-handling/{id}    # Delete
GET    /api/v1/feedback-collection           # List / index
POST   /api/v1/feedback-collection           # Create
GET    /api/v1/feedback-collection/{id}    # Show
PUT    /api/v1/feedback-collection/{id}    # Update
DELETE /api/v1/feedback-collection/{id}    # Delete
```

### D4: Document & Certificate Issuance

**Status:** ⬜ Pending

#### `F.D4.1` — Certificate Request

##### `T.D4.1.1` — Request Certificate

**Sub-Tasks:**

- `ST.D4.1.1.1` Student submits request
- `ST.D4.1.1.2` Select certificate type

##### `T.D4.1.2` — Approval Workflow

**Sub-Tasks:**

- `ST.D4.1.2.1` Send request for approval
- `ST.D4.1.2.2` Track approval stages

#### `F.D4.2` — Certificate Issuance

##### `T.D4.2.1` — Issue Certificate

**Sub-Tasks:**

- `ST.D4.2.1.1` Generate certificate PDF
- `ST.D4.2.1.2` Print & handover certificate

##### `T.D4.2.2` — Record Issuance

**Sub-Tasks:**

- `ST.D4.2.2.1` Log certificate number
- `ST.D4.2.2.2` Store issuance date

**Suggested DB Tables for `D4` — Document & Certificate Issuance:**

- `certificate_templates`
- `certificate_requests`
- `certificates_issued`

**Key API Endpoints for `D4`:**

```
GET    /api/v1/certificate-request           # List / index
POST   /api/v1/certificate-request           # Create
GET    /api/v1/certificate-request/{id}    # Show
PUT    /api/v1/certificate-request/{id}    # Update
DELETE /api/v1/certificate-request/{id}    # Delete
GET    /api/v1/certificate-issuance           # List / index
POST   /api/v1/certificate-issuance           # Create
GET    /api/v1/certificate-issuance/{id}    # Show
PUT    /api/v1/certificate-issuance/{id}    # Update
DELETE /api/v1/certificate-issuance/{id}    # Delete
```

### Screen Design Requirements — Module D


### Report Requirements — Module D

- Module-level summary report with filters and export

### Test Case Requirements — Module D

| Test Type | Scope |
|---|---|
| **Unit Tests** | All service classes and model methods in Module D |
| **Feature Tests** | All API endpoints — happy path, validation errors, auth failures |
| **Browser Tests** | Form submissions, list pagination, filter/search, export |
| **Functional Tests** | End-to-end business workflows (e.g., create → approve → complete lifecycle) |

---

## Module E: Student Information System (SIS)

| | |
|---|---|
| **Module Code** | `E` |
| **App Type** | Both |
| **Description** | Central student registry — master data, academic info, health records, parent access. |
| **Total Sub-Modules** | 5 |
| **Total Features (Tasks)** | 17 |
| **Total Sub-Tasks** | 35 |

### Sub-Module Status

| Sub-Mod Code | Sub-Module Name | App Type | Status |
|---|---|---|---|
| `E1` | Student Master Data Management | Both | ✅ Completed 100% |
| `E2` | Student Academic Information | Both | ✅ Completed 100% |
| `E3` | Student Attendance Records | Both | ✅ Completed 80% |
| `E4` | Student Health & Medical Records | Both | ✅ Completed 100% |
| `E5` | Parent & Guardian Portal Access | Both | ✅ Completed 100% |

### E1: Student Master Data Management

**Status:** ✅ Completed 100%

#### `F.E1.1` — Student Profile

##### `T.E1.1.1` — Create Student Record

**Sub-Tasks:**

- `ST.E1.1.1.1` Enter basic details (Name, DOB, Gender)
- `ST.E1.1.1.2` Capture parent/guardian information
- `ST.E1.1.1.3` Assign unique student ID

##### `T.E1.1.2` — Edit Student Profile

**Sub-Tasks:**

- `ST.E1.1.2.1` Update contact details
- `ST.E1.1.2.2` Modify demographic information

#### `F.E1.2` — Student Address & Family

##### `T.E1.2.1` — Manage Address

**Sub-Tasks:**

- `ST.E1.2.1.1` Add permanent and correspondence address
- `ST.E1.2.1.2` Link geo-location for transport planning

##### `T.E1.2.2` — Family Information

**Sub-Tasks:**

- `ST.E1.2.2.1` Add father/mother/guardian details
- `ST.E1.2.2.2` Add sibling mapping for discounts

**Suggested DB Tables for `E1` — Student Master Data Management:**

- `student_master_data_management_master`
- `student_master_data_management_transactions`
- `student_master_data_management_logs`

**Key API Endpoints for `E1`:**

```
GET    /api/v1/student-profile           # List / index
POST   /api/v1/student-profile           # Create
GET    /api/v1/student-profile/{id}    # Show
PUT    /api/v1/student-profile/{id}    # Update
DELETE /api/v1/student-profile/{id}    # Delete
GET    /api/v1/student-address---family           # List / index
POST   /api/v1/student-address---family           # Create
GET    /api/v1/student-address---family/{id}    # Show
PUT    /api/v1/student-address---family/{id}    # Update
DELETE /api/v1/student-address---family/{id}    # Delete
```

### E2: Student Academic Information

**Status:** ✅ Completed 100%

#### `F.E2.1` — Class & Section Allocation

##### `T.E2.1.1` — Assign Class

**Sub-Tasks:**

- `ST.E2.1.1.1` Allocate class & section
- `ST.E2.1.1.2` Assign roll number automatically

##### `T.E2.1.2` — Modify Class Allocation

**Sub-Tasks:**

- `ST.E2.1.2.1` Shift student between sections
- `ST.E2.1.2.2` Record reason for movement

#### `F.E2.2` — Subject Mapping

##### `T.E2.2.1` — Assign Subjects

**Sub-Tasks:**

- `ST.E2.2.1.1` Auto-assign core subjects
- `ST.E2.2.1.2` Add/remove elective subjects

**Suggested DB Tables for `E2` — Student Academic Information:**

- `student_academic_information_master`
- `student_academic_information_transactions`
- `student_academic_information_logs`

**Key API Endpoints for `E2`:**

```
GET    /api/v1/class---section-allocation           # List / index
POST   /api/v1/class---section-allocation           # Create
GET    /api/v1/class---section-allocation/{id}    # Show
PUT    /api/v1/class---section-allocation/{id}    # Update
DELETE /api/v1/class---section-allocation/{id}    # Delete
GET    /api/v1/subject-mapping           # List / index
POST   /api/v1/subject-mapping           # Create
GET    /api/v1/subject-mapping/{id}    # Show
PUT    /api/v1/subject-mapping/{id}    # Update
DELETE /api/v1/subject-mapping/{id}    # Delete
```

### E3: Student Attendance Records

**Status:** ✅ Completed 80%

#### `F.E3.1` — Daily Attendance

##### `T.E3.1.1` — Mark Attendance

**Sub-Tasks:**

- `ST.E3.1.1.1` Mark present/absent/late
- `ST.E3.1.1.2` Record reason for absence

##### `T.E3.1.2` — Attendance Corrections

**Sub-Tasks:**

- `ST.E3.1.2.1` Allow correction requests
- `ST.E3.1.2.2` Track edit history

#### `F.E3.2` — Attendance Reports

##### `T.E3.2.1` — Generate Reports

**Sub-Tasks:**

- `ST.E3.2.1.1` Daily attendance report
- `ST.E3.2.1.2` Monthly & yearly attendance summary

**Suggested DB Tables for `E3` — Student Attendance Records:**

- `student_attendances`
- `attendance_corrections`
- `attendance_reports`

**Key API Endpoints for `E3`:**

```
GET    /api/v1/daily-attendance           # List / index
POST   /api/v1/daily-attendance           # Create
GET    /api/v1/daily-attendance/{id}    # Show
PUT    /api/v1/daily-attendance/{id}    # Update
DELETE /api/v1/daily-attendance/{id}    # Delete
GET    /api/v1/attendance-reports           # List / index
POST   /api/v1/attendance-reports           # Create
GET    /api/v1/attendance-reports/{id}    # Show
PUT    /api/v1/attendance-reports/{id}    # Update
DELETE /api/v1/attendance-reports/{id}    # Delete
```

### E4: Student Health & Medical Records

**Status:** ✅ Completed 100%

#### `F.E4.1` — Medical Profile

##### `T.E4.1.1` — Record Health Details

**Sub-Tasks:**

- `ST.E4.1.1.1` Add medical conditions
- `ST.E4.1.1.2` Add allergy information

##### `T.E4.1.2` — Vaccination History

**Sub-Tasks:**

- `ST.E4.1.2.1` Record vaccination dates
- `ST.E4.1.2.2` Upload certificates

#### `F.E4.2` — Medical Incidents

##### `T.E4.2.1` — Record Incident

**Sub-Tasks:**

- `ST.E4.2.1.1` Enter incident details
- `ST.E4.2.1.2` Upload doctor's prescription

##### `T.E4.2.2` — Follow-up Tracking

**Sub-Tasks:**

- `ST.E4.2.2.1` Schedule follow-up
- `ST.E4.2.2.2` Record recovery progress

**Suggested DB Tables for `E4` — Student Health & Medical Records:**

- `student_health_medical_records_master`
- `student_health_medical_records_transactions`
- `student_health_medical_records_logs`

**Key API Endpoints for `E4`:**

```
GET    /api/v1/medical-profile           # List / index
POST   /api/v1/medical-profile           # Create
GET    /api/v1/medical-profile/{id}    # Show
PUT    /api/v1/medical-profile/{id}    # Update
DELETE /api/v1/medical-profile/{id}    # Delete
GET    /api/v1/medical-incidents           # List / index
POST   /api/v1/medical-incidents           # Create
GET    /api/v1/medical-incidents/{id}    # Show
PUT    /api/v1/medical-incidents/{id}    # Update
DELETE /api/v1/medical-incidents/{id}    # Delete
```

### E5: Parent & Guardian Portal Access

**Status:** ✅ Completed 100%

#### `F.E5.1` — Parent Accounts

##### `T.E5.1.1` — Create Parent Login

**Sub-Tasks:**

- `ST.E5.1.1.1` Link parent to student(s)
- `ST.E5.1.1.2` Send login credentials

##### `T.E5.1.2` — Manage Parent Access

**Sub-Tasks:**

- `ST.E5.1.2.1` Enable/disable access
- `ST.E5.1.2.2` Reset parent password

#### `F.E5.2` — Parent Communication

##### `T.E5.2.1` — Parent Notifications

**Sub-Tasks:**

- `ST.E5.2.1.1` Send fee reminders
- `ST.E5.2.1.2` Send academic announcements

**Suggested DB Tables for `E5` — Parent & Guardian Portal Access:**

- `parent_notifications`
- `parent_messages`
- `parent_document_access`

**Key API Endpoints for `E5`:**

```
GET    /api/v1/parent-accounts           # List / index
POST   /api/v1/parent-accounts           # Create
GET    /api/v1/parent-accounts/{id}    # Show
PUT    /api/v1/parent-accounts/{id}    # Update
DELETE /api/v1/parent-accounts/{id}    # Delete
GET    /api/v1/parent-communication           # List / index
POST   /api/v1/parent-communication           # Create
GET    /api/v1/parent-communication/{id}    # Show
PUT    /api/v1/parent-communication/{id}    # Update
DELETE /api/v1/parent-communication/{id}    # Delete
```

### Screen Design Requirements — Module E


### Report Requirements — Module E

- **Attendance Reports**: Tabular report with date range filter, export to PDF/Excel/CSV

### Test Case Requirements — Module E

| Test Type | Scope |
|---|---|
| **Unit Tests** | All service classes and model methods in Module E |
| **Feature Tests** | All API endpoints — happy path, validation errors, auth failures |
| **Browser Tests** | Form submissions, list pagination, filter/search, export |
| **Functional Tests** | End-to-end business workflows (e.g., create → approve → complete lifecycle) |

---

## Module F: Attendance Management

| | |
|---|---|
| **Module Code** | `F` |
| **App Type** | Both |
| **Description** | Student & staff attendance — daily, period-wise, analytics, leave sync, biometric integration. |
| **Total Sub-Modules** | 5 |
| **Total Features (Tasks)** | 16 |
| **Total Sub-Tasks** | 34 |

### Sub-Module Status

| Sub-Mod Code | Sub-Module Name | App Type | Status |
|---|---|---|---|
| `F1` | Student Daily Attendance | Both | ✅ Completed 100% |
| `F2` | Student Period/Subject Attendance | Both | ⬜ Pending |
| `F3` | Student Attendance Analytics | Both | ⬜ Pending |
| `F4` | Staff Attendance (Teaching & Non-Teaching) | Both | ✅ Completed 100% |
| `F5` | Staff Attendance Analytics | Both | ⬜ Pending |

### F1: Student Daily Attendance

**Status:** ✅ Completed 100%

#### `F.F1.1` — Attendance Marking

##### `T.F1.1.1` — Mark Daily Attendance

**Sub-Tasks:**

- `ST.F1.1.1.1` Select class & section
- `ST.F1.1.1.2` Mark Present/Absent/Late/Half-Day
- `ST.F1.1.1.3` Record absence reason

##### `T.F1.1.2` — Bulk Attendance Entry

**Sub-Tasks:**

- `ST.F1.1.2.1` Upload CSV attendance sheet
- `ST.F1.1.2.2` Validate roll numbers
- `ST.F1.1.2.3` Auto-update attendance records

#### `F.F1.2` — Attendance Corrections

##### `T.F1.2.1` — Request Correction

**Sub-Tasks:**

- `ST.F1.2.1.1` Student/Parent submit correction request
- `ST.F1.2.1.2` Attach supporting document

##### `T.F1.2.2` — Approve/Reject Correction

**Sub-Tasks:**

- `ST.F1.2.2.1` Teacher reviews correction request
- `ST.F1.2.2.2` Admin final approval with audit log

**Suggested DB Tables for `F1` — Student Daily Attendance:**

- `student_attendances`
- `attendance_corrections`
- `attendance_reports`

**Key API Endpoints for `F1`:**

```
GET    /api/v1/attendance-marking           # List / index
POST   /api/v1/attendance-marking           # Create
GET    /api/v1/attendance-marking/{id}    # Show
PUT    /api/v1/attendance-marking/{id}    # Update
DELETE /api/v1/attendance-marking/{id}    # Delete
GET    /api/v1/attendance-corrections           # List / index
POST   /api/v1/attendance-corrections           # Create
GET    /api/v1/attendance-corrections/{id}    # Show
PUT    /api/v1/attendance-corrections/{id}    # Update
DELETE /api/v1/attendance-corrections/{id}    # Delete
```

### F2: Student Period/Subject Attendance

**Status:** ⬜ Pending

#### `F.F2.1` — Period Attendance

##### `T.F2.1.1` — Mark Period Attendance

**Sub-Tasks:**

- `ST.F2.1.1.1` Teacher selects timetable period
- `ST.F2.1.1.2` Mark attendance per subject

##### `T.F2.1.2` — Auto-Fill Features

**Sub-Tasks:**

- `ST.F2.1.2.1` Auto-fill present for all
- `ST.F2.1.2.2` Auto-sync with daily attendance

**Suggested DB Tables for `F2` — Student Period/Subject Attendance:**

- `student_attendances`
- `attendance_corrections`
- `attendance_reports`

**Key API Endpoints for `F2`:**

```
GET    /api/v1/period-attendance           # List / index
POST   /api/v1/period-attendance           # Create
GET    /api/v1/period-attendance/{id}    # Show
PUT    /api/v1/period-attendance/{id}    # Update
DELETE /api/v1/period-attendance/{id}    # Delete
```

### F3: Student Attendance Analytics

**Status:** ⬜ Pending

#### `F.F3.1` — Reports

##### `T.F3.1.1` — Generate Attendance Reports

**Sub-Tasks:**

- `ST.F3.1.1.1` Daily attendance report
- `ST.F3.1.1.2` Monthly/Term-wise attendance summary

##### `T.F3.1.2` — Absentee Patterns

**Sub-Tasks:**

- `ST.F3.1.2.1` Identify frequent absentees
- `ST.F3.1.2.2` Detect long absence streaks

#### `F.F3.2` — Notifications

##### `T.F3.2.1` — Send Alerts

**Sub-Tasks:**

- `ST.F3.2.1.1` Send SMS/Email for absence
- `ST.F3.2.1.2` Auto-alert parents for late arrival

**Suggested DB Tables for `F3` — Student Attendance Analytics:**

- `student_attendances`
- `attendance_corrections`
- `attendance_reports`

**Key API Endpoints for `F3`:**

```
GET    /api/v1/reports           # List / index
POST   /api/v1/reports           # Create
GET    /api/v1/reports/{id}    # Show
PUT    /api/v1/reports/{id}    # Update
DELETE /api/v1/reports/{id}    # Delete
GET    /api/v1/notifications           # List / index
POST   /api/v1/notifications           # Create
GET    /api/v1/notifications/{id}    # Show
PUT    /api/v1/notifications/{id}    # Update
DELETE /api/v1/notifications/{id}    # Delete
```

### F4: Staff Attendance (Teaching & Non-Teaching)

**Status:** ✅ Completed 100%

#### `F.F4.1` — Staff Check-In/Out

##### `T.F4.1.1` — Mark Staff Attendance

**Sub-Tasks:**

- `ST.F4.1.1.1` Record check-in time
- `ST.F4.1.1.2` Record check-out time

##### `T.F4.1.2` — Device Integration

**Sub-Tasks:**

- `ST.F4.1.2.1` Sync biometric attendance
- `ST.F4.1.2.2` Auto-detect anomalies

#### `F.F4.2` — Leave & Attendance Sync

##### `T.F4.2.1` — Leave Integration

**Sub-Tasks:**

- `ST.F4.2.1.1` Auto-mark leave status
- `ST.F4.2.1.2` Sync approved leave with attendance

##### `T.F4.2.2` — Attendance Regularization

**Sub-Tasks:**

- `ST.F4.2.2.1` Submit regularization request
- `ST.F4.2.2.2` Approve/Reject regularization

**Suggested DB Tables for `F4` — Staff Attendance (Teaching & Non-Teaching):**

- `staff_attendances`
- `staff_leaves`
- `leave_types`
- `biometric_logs`

**Key API Endpoints for `F4`:**

```
GET    /api/v1/staff-check-in-out           # List / index
POST   /api/v1/staff-check-in-out           # Create
GET    /api/v1/staff-check-in-out/{id}    # Show
PUT    /api/v1/staff-check-in-out/{id}    # Update
DELETE /api/v1/staff-check-in-out/{id}    # Delete
GET    /api/v1/leave---attendance-sync           # List / index
POST   /api/v1/leave---attendance-sync           # Create
GET    /api/v1/leave---attendance-sync/{id}    # Show
PUT    /api/v1/leave---attendance-sync/{id}    # Update
DELETE /api/v1/leave---attendance-sync/{id}    # Delete
```

### F5: Staff Attendance Analytics

**Status:** ⬜ Pending

#### `F.F5.1` — Reports

##### `T.F5.1.1` — Generate Reports

**Sub-Tasks:**

- `ST.F5.1.1.1` Daily staff attendance report
- `ST.F5.1.1.2` Monthly working hours summary

##### `T.F5.1.2` — Department-Level Stats

**Sub-Tasks:**

- `ST.F5.1.2.1` Teacher attendance summary
- `ST.F5.1.2.2` Non-teaching attendance patterns

#### `F.F5.2` — Alerts

##### `T.F5.2.1` — Late/Early Alerts

**Sub-Tasks:**

- `ST.F5.2.1.1` Auto-alert HR for late arrival
- `ST.F5.2.1.2` Notify department head

**Suggested DB Tables for `F5` — Staff Attendance Analytics:**

- `staff_attendances`
- `staff_leaves`
- `leave_types`
- `biometric_logs`

**Key API Endpoints for `F5`:**

```
GET    /api/v1/reports           # List / index
POST   /api/v1/reports           # Create
GET    /api/v1/reports/{id}    # Show
PUT    /api/v1/reports/{id}    # Update
DELETE /api/v1/reports/{id}    # Delete
GET    /api/v1/alerts           # List / index
POST   /api/v1/alerts           # Create
GET    /api/v1/alerts/{id}    # Show
PUT    /api/v1/alerts/{id}    # Update
DELETE /api/v1/alerts/{id}    # Delete
```

### Screen Design Requirements — Module F


### Report Requirements — Module F

- **Reports**: Tabular report with date range filter, export to PDF/Excel/CSV

### Test Case Requirements — Module F

| Test Type | Scope |
|---|---|
| **Unit Tests** | All service classes and model methods in Module F |
| **Feature Tests** | All API endpoints — happy path, validation errors, auth failures |
| **Browser Tests** | Form submissions, list pagination, filter/search, export |
| **Functional Tests** | End-to-end business workflows (e.g., create → approve → complete lifecycle) |

---

## Module G: Advanced Timetable Management

| | |
|---|---|
| **Module Code** | `G` |
| **App Type** | Both |
| **Description** | AI-driven timetable engine with constraint solving, drag-drop editing, substitution, publishing. |
| **Total Sub-Modules** | 9 |
| **Total Features (Tasks)** | 20 |
| **Total Sub-Tasks** | 47 |

### Sub-Module Status

| Sub-Mod Code | Sub-Module Name | App Type | Status |
|---|---|---|---|
| `G1` | Academic Structure Mapping | Both | ✅ Completed 100% |
| `G2` | Teacher Workload & Availability | Both | ✅ Completed 100% |
| `G3` | Room & Resource Constraints | Both | ✅ Completed 100% |
| `G4` | Timetable Rule Engine | Both | 🔄 In-Progress 50% |
| `G5` | Automatic Timetable Generation | Both | 🔄 In-Progress 20% |
| `G6` | Manual Timetable Editing | Both | ⬜ Pending |
| `G7` | Substitution Management | Both | 🔄 In-Progress 20% |
| `G8` | Timetable Publishing | Both | 🔄 In-Progress 20% |
| `G9` | Analytics & Reports | Both | 🔄 In-Progress 20% |

### G1: Academic Structure Mapping

**Status:** ✅ Completed 100%

#### `F.G1.1` — Class & Section Setup

##### `T.G1.1.1` — Configure Academic Structure

**Sub-Tasks:**

- `ST.G1.1.1.1` Define classes & sections
- `ST.G1.1.1.2` Map teachers to class sections
- `ST.G1.1.1.3` Assign subjects to class/section

#### `F.G1.2` — Subject Mapping

##### `T.G1.2.1` — Assign Subjects

**Sub-Tasks:**

- `ST.G1.2.1.1` Map core subjects automatically
- `ST.G1.2.1.2` Add elective subjects
- `ST.G1.2.1.3` Set weekly periods for each subject

**Suggested DB Tables for `G1` — Academic Structure Mapping:**

- `academic_sessions`
- `calendar_events`
- `holidays`

**Key API Endpoints for `G1`:**

```
GET    /api/v1/class---section-setup           # List / index
POST   /api/v1/class---section-setup           # Create
GET    /api/v1/class---section-setup/{id}    # Show
PUT    /api/v1/class---section-setup/{id}    # Update
DELETE /api/v1/class---section-setup/{id}    # Delete
GET    /api/v1/subject-mapping           # List / index
POST   /api/v1/subject-mapping           # Create
GET    /api/v1/subject-mapping/{id}    # Show
PUT    /api/v1/subject-mapping/{id}    # Update
DELETE /api/v1/subject-mapping/{id}    # Delete
```

### G2: Teacher Workload & Availability

**Status:** ✅ Completed 100%

#### `F.G2.1` — Teacher Constraints

##### `T.G2.1.1` — Define Teacher Availability

**Sub-Tasks:**

- `ST.G2.1.1.1` Set available days
- `ST.G2.1.1.2` Set free/busy slots
- `ST.G2.1.1.3` Limit max teaching hours per day

##### `T.G2.1.2` — Teacher Preferences

**Sub-Tasks:**

- `ST.G2.1.2.1` Preferred periods
- `ST.G2.1.2.2` Restricted periods

#### `F.G2.2` — Workload Allocation

##### `T.G2.2.1` — Auto Calculate Workload

**Sub-Tasks:**

- `ST.G2.2.1.1` Calculate assigned weekly hours
- `ST.G2.2.1.2` Detect overload or underload

**Suggested DB Tables for `G2` — Teacher Workload & Availability:**

- `teacher_availability`
- `teacher_preferences`
- `workload_configs`

**Key API Endpoints for `G2`:**

```
GET    /api/v1/teacher-constraints           # List / index
POST   /api/v1/teacher-constraints           # Create
GET    /api/v1/teacher-constraints/{id}    # Show
PUT    /api/v1/teacher-constraints/{id}    # Update
DELETE /api/v1/teacher-constraints/{id}    # Delete
GET    /api/v1/workload-allocation           # List / index
POST   /api/v1/workload-allocation           # Create
GET    /api/v1/workload-allocation/{id}    # Show
PUT    /api/v1/workload-allocation/{id}    # Update
DELETE /api/v1/workload-allocation/{id}    # Delete
```

### G3: Room & Resource Constraints

**Status:** ✅ Completed 100%

#### `F.G3.1` — Room Configuration

##### `T.G3.1.1` — Define Room Details

**Sub-Tasks:**

- `ST.G3.1.1.1` Enter capacity
- `ST.G3.1.1.2` Assign room type (Lab/Classroom)

##### `T.G3.1.2` — Room Constraints

**Sub-Tasks:**

- `ST.G3.1.2.1` Set availability timeline
- `ST.G3.1.2.2` Prevent double booking

#### `F.G3.2` — Resource Allocation

##### `T.G3.2.1` — Assign Resources

**Sub-Tasks:**

- `ST.G3.2.1.1` Map labs to subjects
- `ST.G3.2.1.2` Define special equipment needs

**Suggested DB Tables for `G3` — Room & Resource Constraints:**

- `rooms`
- `room_constraints`
- `lab_resources`

**Key API Endpoints for `G3`:**

```
GET    /api/v1/room-configuration           # List / index
POST   /api/v1/room-configuration           # Create
GET    /api/v1/room-configuration/{id}    # Show
PUT    /api/v1/room-configuration/{id}    # Update
DELETE /api/v1/room-configuration/{id}    # Delete
GET    /api/v1/resource-allocation           # List / index
POST   /api/v1/resource-allocation           # Create
GET    /api/v1/resource-allocation/{id}    # Show
PUT    /api/v1/resource-allocation/{id}    # Update
DELETE /api/v1/resource-allocation/{id}    # Delete
```

### G4: Timetable Rule Engine

**Status:** 🔄 In-Progress 50%

#### `F.G4.1` — Hard Constraints

##### `T.G4.1.1` — Mandatory Rules

**Sub-Tasks:**

- `ST.G4.1.1.1` No teacher conflict
- `ST.G4.1.1.2` No student group conflict
- `ST.G4.1.1.3` No room conflict

#### `F.G4.2` — Soft Constraints

##### `T.G4.2.1` — Preference Rules

**Sub-Tasks:**

- `ST.G4.2.1.1` Avoid free periods at day start
- `ST.G4.2.1.2` Balance subject load

**Suggested DB Tables for `G4` — Timetable Rule Engine:**

- `timetable_rule_engine_master`
- `timetable_rule_engine_transactions`
- `timetable_rule_engine_logs`

**Key API Endpoints for `G4`:**

```
GET    /api/v1/hard-constraints           # List / index
POST   /api/v1/hard-constraints           # Create
GET    /api/v1/hard-constraints/{id}    # Show
PUT    /api/v1/hard-constraints/{id}    # Update
DELETE /api/v1/hard-constraints/{id}    # Delete
GET    /api/v1/soft-constraints           # List / index
POST   /api/v1/soft-constraints           # Create
GET    /api/v1/soft-constraints/{id}    # Show
PUT    /api/v1/soft-constraints/{id}    # Update
DELETE /api/v1/soft-constraints/{id}    # Delete
```

### G5: Automatic Timetable Generation

**Status:** 🔄 In-Progress 20%

#### `F.G5.1` — Scheduler Engine

##### `T.G5.1.1` — Generate Timetable

**Sub-Tasks:**

- `ST.G5.1.1.1` Run auto-allocation engine
- `ST.G5.1.1.2` Apply recursive conflict resolution
- `ST.G5.1.1.3` Use heuristic optimization

##### `T.G5.1.2` — Validation

**Sub-Tasks:**

- `ST.G5.1.2.1` Check unresolved conflicts
- `ST.G5.1.2.2` Generate conflict summary

**Suggested DB Tables for `G5` — Automatic Timetable Generation:**

- `automatic_timetable_generation_master`
- `automatic_timetable_generation_transactions`
- `automatic_timetable_generation_logs`

**Key API Endpoints for `G5`:**

```
GET    /api/v1/scheduler-engine           # List / index
POST   /api/v1/scheduler-engine           # Create
GET    /api/v1/scheduler-engine/{id}    # Show
PUT    /api/v1/scheduler-engine/{id}    # Update
DELETE /api/v1/scheduler-engine/{id}    # Delete
```

### G6: Manual Timetable Editing

**Status:** ⬜ Pending

#### `F.G6.1` — Drag & Drop Editing

##### `T.G6.1.1` — Modify Timetable

**Sub-Tasks:**

- `ST.G6.1.1.1` Move subjects across periods
- `ST.G6.1.1.2` Swap teacher or room
- `ST.G6.1.1.3` Override constraints (Admin only)

#### `F.G6.2` — Conflict Warnings

##### `T.G6.2.1` — Live Conflict Checks

**Sub-Tasks:**

- `ST.G6.2.1.1` Teacher conflict alerts
- `ST.G6.2.1.2` Room capacity conflict alerts

**Suggested DB Tables for `G6` — Manual Timetable Editing:**

- `manual_timetable_editing_master`
- `manual_timetable_editing_transactions`
- `manual_timetable_editing_logs`

**Key API Endpoints for `G6`:**

```
GET    /api/v1/drag---drop-editing           # List / index
POST   /api/v1/drag---drop-editing           # Create
GET    /api/v1/drag---drop-editing/{id}    # Show
PUT    /api/v1/drag---drop-editing/{id}    # Update
DELETE /api/v1/drag---drop-editing/{id}    # Delete
GET    /api/v1/conflict-warnings           # List / index
POST   /api/v1/conflict-warnings           # Create
GET    /api/v1/conflict-warnings/{id}    # Show
PUT    /api/v1/conflict-warnings/{id}    # Update
DELETE /api/v1/conflict-warnings/{id}    # Delete
```

### G7: Substitution Management

**Status:** 🔄 In-Progress 20%

#### `F.G7.1` — Absentee Management

##### `T.G7.1.1` — Assign Substitute Teacher

**Sub-Tasks:**

- `ST.G7.1.1.1` Auto-suggest substitute
- `ST.G7.1.1.2` Manual assignment with approval

#### `F.G7.2` — Teacher Absence Workflow

##### `T.G7.2.1` — Notify Substitutes

**Sub-Tasks:**

- `ST.G7.2.1.1` Send SMS/Email
- `ST.G7.2.1.2` In-app notification

**Suggested DB Tables for `G7` — Substitution Management:**

- `teacher_absences`
- `substitution_assignments`

**Key API Endpoints for `G7`:**

```
GET    /api/v1/absentee-management           # List / index
POST   /api/v1/absentee-management           # Create
GET    /api/v1/absentee-management/{id}    # Show
PUT    /api/v1/absentee-management/{id}    # Update
DELETE /api/v1/absentee-management/{id}    # Delete
GET    /api/v1/teacher-absence-workflow           # List / index
POST   /api/v1/teacher-absence-workflow           # Create
GET    /api/v1/teacher-absence-workflow/{id}    # Show
PUT    /api/v1/teacher-absence-workflow/{id}    # Update
DELETE /api/v1/teacher-absence-workflow/{id}    # Delete
```

### G8: Timetable Publishing

**Status:** 🔄 In-Progress 20%

#### `F.G8.1` — Publish Timetable

##### `T.G8.1.1` — Generate Outputs

**Sub-Tasks:**

- `ST.G8.1.1.1` Student timetable PDF
- `ST.G8.1.1.2` Teacher timetable PDF
- `ST.G8.1.1.3` Room timetable PDF

#### `F.G8.2` — Multi-format Export

##### `T.G8.2.1` — Export Options

**Sub-Tasks:**

- `ST.G8.2.1.1` Excel export
- `ST.G8.2.1.2` ICS calendar export

**Suggested DB Tables for `G8` — Timetable Publishing:**

- `timetable_publishing_master`
- `timetable_publishing_transactions`
- `timetable_publishing_logs`

**Key API Endpoints for `G8`:**

```
GET    /api/v1/publish-timetable           # List / index
POST   /api/v1/publish-timetable           # Create
GET    /api/v1/publish-timetable/{id}    # Show
PUT    /api/v1/publish-timetable/{id}    # Update
DELETE /api/v1/publish-timetable/{id}    # Delete
GET    /api/v1/multi-format-export           # List / index
POST   /api/v1/multi-format-export           # Create
GET    /api/v1/multi-format-export/{id}    # Show
PUT    /api/v1/multi-format-export/{id}    # Update
DELETE /api/v1/multi-format-export/{id}    # Delete
```

### G9: Analytics & Reports

**Status:** 🔄 In-Progress 20%

#### `F.G9.1` — Timetable Reports

##### `T.G9.1.1` — Generate Reports

**Sub-Tasks:**

- `ST.G9.1.1.1` Teacher workload report
- `ST.G9.1.1.2` Room utilization report

#### `F.G9.2` — AI Insights

##### `T.G9.2.1` — Optimization Suggestions

**Sub-Tasks:**

- `ST.G9.2.1.1` Suggest redistribution of load
- `ST.G9.2.1.2` Highlight conflict-prone times

**Suggested DB Tables for `G9` — Analytics & Reports:**

- `ml_model_configs`
- `prediction_results`
- `analytics_snapshots`

**Key API Endpoints for `G9`:**

```
GET    /api/v1/timetable-reports           # List / index
POST   /api/v1/timetable-reports           # Create
GET    /api/v1/timetable-reports/{id}    # Show
PUT    /api/v1/timetable-reports/{id}    # Update
DELETE /api/v1/timetable-reports/{id}    # Delete
GET    /api/v1/ai-insights           # List / index
POST   /api/v1/ai-insights           # Create
GET    /api/v1/ai-insights/{id}    # Show
PUT    /api/v1/ai-insights/{id}    # Update
DELETE /api/v1/ai-insights/{id}    # Delete
```

### Screen Design Requirements — Module G


### Report Requirements — Module G

- **Multi-format Export**: Tabular report with date range filter, export to PDF/Excel/CSV
- **Timetable Reports**: Tabular report with date range filter, export to PDF/Excel/CSV

### Test Case Requirements — Module G

| Test Type | Scope |
|---|---|
| **Unit Tests** | All service classes and model methods in Module G |
| **Feature Tests** | All API endpoints — happy path, validation errors, auth failures |
| **Browser Tests** | Form submissions, list pagination, filter/search, export |
| **Functional Tests** | End-to-end business workflows (e.g., create → approve → complete lifecycle) |

---

## Module H: Academics Management

| | |
|---|---|
| **Module Code** | `H` |
| **App Type** | Both |
| **Description** | Curriculum setup, lesson planning, homework, academic calendar, skill tracking, co-curricular. |
| **Total Sub-Modules** | 7 |
| **Total Features (Tasks)** | 26 |
| **Total Sub-Tasks** | 54 |

### Sub-Module Status

| Sub-Mod Code | Sub-Module Name | App Type | Status |
|---|---|---|---|
| `H1` | Academic Structure & Curriculum | Both | ✅ Completed 50% |
| `H2` | Lesson Planning & Delivery | Both | ⬜ Pending |
| `H3` | Homework & Assignments | Both | ✅ Completed 100% |
| `H4` | Academic Calendar & Events | Both | ✅ Completed 80% |
| `H5` | Teacher Workload & Distribution | Both | 🔄 In-Progress 50% |
| `H6` | Skill & Competency Tracking | Both | ✅ Completed 100% |
| `H7` | Co-Curricular & Activity Management | Both | ⬜ Not Started |

### H1: Academic Structure & Curriculum

**Status:** ✅ Completed 50%

#### `F.H1.1` — Academic Session

##### `T.H1.1.1` — Create Session

**Sub-Tasks:**

- `ST.H1.1.1.1` Define academic session name
- `ST.H1.1.1.2` Set session start & end dates

##### `T.H1.1.2` — Activate/Deactivate Session

**Sub-Tasks:**

- `ST.H1.1.2.1` Mark session as active
- `ST.H1.1.2.2` Prevent edits to closed session

#### `F.H1.2` — Curriculum Mapping

##### `T.H1.2.1` — Assign Subjects to Class

**Sub-Tasks:**

- `ST.H1.2.1.1` Map core subjects
- `ST.H1.2.1.2` Add/remove electives

##### `T.H1.2.2` — Define Lesson Units

**Sub-Tasks:**

- `ST.H1.2.2.1` Create unit/chapter structure
- `ST.H1.2.2.2` Assign learning outcomes

**Suggested DB Tables for `H1` — Academic Structure & Curriculum:**

- `curricula`
- `syllabus_units`
- `lesson_topics`
- `board_mappings`

**Key API Endpoints for `H1`:**

```
GET    /api/v1/academic-session           # List / index
POST   /api/v1/academic-session           # Create
GET    /api/v1/academic-session/{id}    # Show
PUT    /api/v1/academic-session/{id}    # Update
DELETE /api/v1/academic-session/{id}    # Delete
GET    /api/v1/curriculum-mapping           # List / index
POST   /api/v1/curriculum-mapping           # Create
GET    /api/v1/curriculum-mapping/{id}    # Show
PUT    /api/v1/curriculum-mapping/{id}    # Update
DELETE /api/v1/curriculum-mapping/{id}    # Delete
```

### H2: Lesson Planning & Delivery

**Status:** ⬜ Pending

#### `F.H2.1` — Lesson Plans

##### `T.H2.1.1` — Create Lesson Plan

**Sub-Tasks:**

- `ST.H2.1.1.1` Define topic & objectives
- `ST.H2.1.1.2` Attach reference materials
- `ST.H2.1.1.3` Tag learning outcomes

##### `T.H2.1.2` — Publish Lesson Plan

**Sub-Tasks:**

- `ST.H2.1.2.1` Notify students & parents
- `ST.H2.1.2.2` Track completion of plan

#### `F.H2.2` — Digital Content

##### `T.H2.2.1` — Upload Content

**Sub-Tasks:**

- `ST.H2.2.1.1` Upload PDF/Video/SCORM
- `ST.H2.2.1.2` Add description & metadata

##### `T.H2.2.2` — Content Assignment

**Sub-Tasks:**

- `ST.H2.2.2.1` Assign content to class
- `ST.H2.2.2.2` Schedule content availability

**Suggested DB Tables for `H2` — Lesson Planning & Delivery:**

- `subscription_plans`
- `tenant_subscriptions`
- `invoices`
- `payments`

**Key API Endpoints for `H2`:**

```
GET    /api/v1/lesson-plans           # List / index
POST   /api/v1/lesson-plans           # Create
GET    /api/v1/lesson-plans/{id}    # Show
PUT    /api/v1/lesson-plans/{id}    # Update
DELETE /api/v1/lesson-plans/{id}    # Delete
GET    /api/v1/digital-content           # List / index
POST   /api/v1/digital-content           # Create
GET    /api/v1/digital-content/{id}    # Show
PUT    /api/v1/digital-content/{id}    # Update
DELETE /api/v1/digital-content/{id}    # Delete
```

### H3: Homework & Assignments

**Status:** ✅ Completed 100%

#### `F.H3.1` — Homework Creation

##### `T.H3.1.1` — Create Homework

**Sub-Tasks:**

- `ST.H3.1.1.1` Select class & subject
- `ST.H3.1.1.2` Enter homework instructions
- `ST.H3.1.1.3` Attach supporting files

##### `T.H3.1.2` — Homework Scheduling

**Sub-Tasks:**

- `ST.H3.1.2.1` Set due date
- `ST.H3.1.2.2` Restrict late submissions

#### `F.H3.2` — Homework Evaluation

##### `T.H3.2.1` — Review Submission

**Sub-Tasks:**

- `ST.H3.2.1.1` View submitted files
- `ST.H3.2.1.2` Evaluate and grade

##### `T.H3.2.2` — Feedback

**Sub-Tasks:**

- `ST.H3.2.2.1` Provide written feedback
- `ST.H3.2.2.2` Send notification to parents

**Suggested DB Tables for `H3` — Homework & Assignments:**

- `homeworks`
- `homework_submissions`
- `homework_grades`

**Key API Endpoints for `H3`:**

```
GET    /api/v1/homework-creation           # List / index
POST   /api/v1/homework-creation           # Create
GET    /api/v1/homework-creation/{id}    # Show
PUT    /api/v1/homework-creation/{id}    # Update
DELETE /api/v1/homework-creation/{id}    # Delete
GET    /api/v1/homework-evaluation           # List / index
POST   /api/v1/homework-evaluation           # Create
GET    /api/v1/homework-evaluation/{id}    # Show
PUT    /api/v1/homework-evaluation/{id}    # Update
DELETE /api/v1/homework-evaluation/{id}    # Delete
```

### H4: Academic Calendar & Events

**Status:** ✅ Completed 80%

#### `F.H4.1` — Event Management

##### `T.H4.1.1` — Create Academic Event

**Sub-Tasks:**

- `ST.H4.1.1.1` Define event name & date
- `ST.H4.1.1.2` Assign event type

##### `T.H4.1.2` — Event Publishing

**Sub-Tasks:**

- `ST.H4.1.2.1` Publish to student/parent portals
- `ST.H4.1.2.2` Send event reminders

#### `F.H4.2` — Holiday Calendar

##### `T.H4.2.1` — Add Holiday

**Sub-Tasks:**

- `ST.H4.2.1.1` Set holiday name
- `ST.H4.2.1.2` Mark as full or half-day

##### `T.H4.2.2` — Holiday Notifications

**Sub-Tasks:**

- `ST.H4.2.2.1` Send SMS/email alerts
- `ST.H4.2.2.2` Auto-apply in attendance

**Suggested DB Tables for `H4` — Academic Calendar & Events:**

- `academic_sessions`
- `calendar_events`
- `holidays`

**Key API Endpoints for `H4`:**

```
GET    /api/v1/event-management           # List / index
POST   /api/v1/event-management           # Create
GET    /api/v1/event-management/{id}    # Show
PUT    /api/v1/event-management/{id}    # Update
DELETE /api/v1/event-management/{id}    # Delete
GET    /api/v1/holiday-calendar           # List / index
POST   /api/v1/holiday-calendar           # Create
GET    /api/v1/holiday-calendar/{id}    # Show
PUT    /api/v1/holiday-calendar/{id}    # Update
DELETE /api/v1/holiday-calendar/{id}    # Delete
```

### H5: Teacher Workload & Distribution

**Status:** 🔄 In-Progress 50%

#### `F.H5.1` — Workload Calculation

##### `T.H5.1.1` — Calculate Teacher Load

**Sub-Tasks:**

- `ST.H5.1.1.1` Compute assigned periods
- `ST.H5.1.1.2` Check against max load limits

##### `T.H5.1.2` — Adjust Load

**Sub-Tasks:**

- `ST.H5.1.2.1` Reassign subjects
- `ST.H5.1.2.2` Balance load across teachers

#### `F.H5.2` — Load Reports

##### `T.H5.2.1` — Generate Load Report

**Sub-Tasks:**

- `ST.H5.2.1.1` Show subject-wise load
- `ST.H5.2.1.2` Department workload summary

**Suggested DB Tables for `H5` — Teacher Workload & Distribution:**

- `teacher_availability`
- `teacher_preferences`
- `workload_configs`

**Key API Endpoints for `H5`:**

```
GET    /api/v1/workload-calculation           # List / index
POST   /api/v1/workload-calculation           # Create
GET    /api/v1/workload-calculation/{id}    # Show
PUT    /api/v1/workload-calculation/{id}    # Update
DELETE /api/v1/workload-calculation/{id}    # Delete
GET    /api/v1/load-reports           # List / index
POST   /api/v1/load-reports           # Create
GET    /api/v1/load-reports/{id}    # Show
PUT    /api/v1/load-reports/{id}    # Update
DELETE /api/v1/load-reports/{id}    # Delete
```

### H6: Skill & Competency Tracking

**Status:** ✅ Completed 100%

#### `F.H6.1` — Skill Framework

##### `T.H6.1.1` — Create Skill Categories

**Sub-Tasks:**

- `ST.H6.1.1.1` Add cognitive/creative skills
- `ST.H6.1.1.2` Define descriptors

##### `T.H6.1.2` — Assign Skills to Subjects

**Sub-Tasks:**

- `ST.H6.1.2.1` Map skills to subject units
- `ST.H6.1.2.2` Define assessment criteria

#### `F.H6.2` — Skill Assessment

##### `T.H6.2.1` — Record Skill Performance

**Sub-Tasks:**

- `ST.H6.2.1.1` Enter skill rating per student
- `ST.H6.2.1.2` Attach evidence or notes

##### `T.H6.2.2` — Skill Reports

**Sub-Tasks:**

- `ST.H6.2.2.1` Download student skill report
- `ST.H6.2.2.2` Generate skill improvement insights

**Suggested DB Tables for `H6` — Skill & Competency Tracking:**

- `skills`
- `skill_categories`
- `learner_skills`
- `skill_assessments`

**Key API Endpoints for `H6`:**

```
GET    /api/v1/skill-framework           # List / index
POST   /api/v1/skill-framework           # Create
GET    /api/v1/skill-framework/{id}    # Show
PUT    /api/v1/skill-framework/{id}    # Update
DELETE /api/v1/skill-framework/{id}    # Delete
GET    /api/v1/skill-assessment           # List / index
POST   /api/v1/skill-assessment           # Create
GET    /api/v1/skill-assessment/{id}    # Show
PUT    /api/v1/skill-assessment/{id}    # Update
DELETE /api/v1/skill-assessment/{id}    # Delete
```

### H7: Co-Curricular & Activity Management

**Status:** ⬜ Not Started

#### `F.H7.1` — Activity Master

##### `T.H7.1.1` — Create Activity

**Sub-Tasks:**

- `ST.H7.1.1.1` Define activity type (Sports, Arts, Club, Competition)
- `ST.H7.1.1.2` Set activity schedule, venue, and in-charge teacher

##### `T.H7.1.2` — Student Participation

**Sub-Tasks:**

- `ST.H7.1.2.1` Enroll students in activities
- `ST.H7.1.2.2` Track attendance and performance in activities

#### `F.H7.2` — Activity Assessment

##### `T.H7.2.1` — Evaluate Performance

**Sub-Tasks:**

- `ST.H7.2.1.1` Record achievements, awards, positions
- `ST.H7.2.1.2` Generate co-curricular transcripts for students

**Suggested DB Tables for `H7` — Co-Curricular & Activity Management:**

- `co_curricular_activity_managem_master`
- `co_curricular_activity_managem_transactions`
- `co_curricular_activity_managem_logs`

**Key API Endpoints for `H7`:**

```
GET    /api/v1/activity-master           # List / index
POST   /api/v1/activity-master           # Create
GET    /api/v1/activity-master/{id}    # Show
PUT    /api/v1/activity-master/{id}    # Update
DELETE /api/v1/activity-master/{id}    # Delete
GET    /api/v1/activity-assessment           # List / index
POST   /api/v1/activity-assessment           # Create
GET    /api/v1/activity-assessment/{id}    # Show
PUT    /api/v1/activity-assessment/{id}    # Update
DELETE /api/v1/activity-assessment/{id}    # Delete
```

### Screen Design Requirements — Module H


### Report Requirements — Module H

- **Load Reports**: Tabular report with date range filter, export to PDF/Excel/CSV

### Test Case Requirements — Module H

| Test Type | Scope |
|---|---|
| **Unit Tests** | All service classes and model methods in Module H |
| **Feature Tests** | All API endpoints — happy path, validation errors, auth failures |
| **Browser Tests** | Form submissions, list pagination, filter/search, export |
| **Functional Tests** | End-to-end business workflows (e.g., create → approve → complete lifecycle) |

---

## Module I: Examination & Gradebook

| | |
|---|---|
| **Module Code** | `I` |
| **App Type** | Both |
| **Description** | Exam structure, scheduling, marks entry, moderation, gradebook, report cards, board patterns, AI analytics. |
| **Total Sub-Modules** | 10 |
| **Total Features (Tasks)** | 23 |
| **Total Sub-Tasks** | 46 |

### Sub-Module Status

| Sub-Mod Code | Sub-Module Name | App Type | Status |
|---|---|---|---|
| `I1` | Exam Structure & Scheme | Both | ✅ Completed 100% |
| `I10` | AI-Based Examination Analytics | Both | ⬜ Not Started |
| `I2` | Exam Timetable Scheduling | Both | ✅ Completed 100% |
| `I3` | Marks Entry & Verification | Both | 🔄 In-Progress 70% |
| `I4` | Moderation Workflow | Both | 🔄 In-Progress 70% |
| `I5` | Gradebook Calculation Engine | Both | 🔄 In-Progress 50% |
| `I6` | Report Cards & Publishing | Both | ⬜ Not Started |
| `I7` | Promotion & Detention Rules | Both | 🔄 In-Progress 50% |
| `I8` | Board Pattern Support (CBSE/ICSE/IB/Cambridge) | Both | 🔄 In-Progress 80% |
| `I9` | Custom Report Card Designer | Both | 🔄 In-Progress 40% |

### I1: Exam Structure & Scheme

**Status:** ✅ Completed 100%

#### `F.I1.1` — Exam Types

##### `T.I1.1.1` — Create Exam Type

**Sub-Tasks:**

- `ST.I1.1.1.1` Define exam name (Unit Test, Mid-Term, Final)
- `ST.I1.1.1.2` Set exam category (Formative/Summative)

##### `T.I1.1.2` — Exam Components

**Sub-Tasks:**

- `ST.I1.1.2.1` Define theory/practical components
- `ST.I1.1.2.2` Set max marks per component

#### `F.I1.2` — Weightage & Scheme

##### `T.I1.2.1` — Define Weightages

**Sub-Tasks:**

- `ST.I1.2.1.1` Assign subject-wise weightages
- `ST.I1.2.1.2` Set grade calculation formula

**Suggested DB Tables for `I1` — Exam Structure & Scheme:**

- `exam_types`
- `exam_schemes`
- `exam_weightages`

**Key API Endpoints for `I1`:**

```
GET    /api/v1/exam-types           # List / index
POST   /api/v1/exam-types           # Create
GET    /api/v1/exam-types/{id}    # Show
PUT    /api/v1/exam-types/{id}    # Update
DELETE /api/v1/exam-types/{id}    # Delete
GET    /api/v1/weightage---scheme           # List / index
POST   /api/v1/weightage---scheme           # Create
GET    /api/v1/weightage---scheme/{id}    # Show
PUT    /api/v1/weightage---scheme/{id}    # Update
DELETE /api/v1/weightage---scheme/{id}    # Delete
```

### I10: AI-Based Examination Analytics

**Status:** ⬜ Not Started

#### `F.I10.1` — Performance Insights

##### `T.I10.1.1` — Analyze Weak Areas

**Sub-Tasks:**

- `ST.I10.1.1.1` Identify student skill gaps
- `ST.I10.1.1.2` Suggest improvement areas

##### `T.I10.1.2` — Predictive Alerts

**Sub-Tasks:**

- `ST.I10.1.2.1` Predict exam performance risk
- `ST.I10.1.2.2` Generate AI-based alerts

**Suggested DB Tables for `I10` — AI-Based Examination Analytics:**

- `ml_model_configs`
- `prediction_results`
- `analytics_snapshots`

**Key API Endpoints for `I10`:**

```
GET    /api/v1/performance-insights           # List / index
POST   /api/v1/performance-insights           # Create
GET    /api/v1/performance-insights/{id}    # Show
PUT    /api/v1/performance-insights/{id}    # Update
DELETE /api/v1/performance-insights/{id}    # Delete
```

### I2: Exam Timetable Scheduling

**Status:** ✅ Completed 100%

#### `F.I2.1` — Timetable Setup

##### `T.I2.1.1` — Create Exam Slots

**Sub-Tasks:**

- `ST.I2.1.1.1` Assign date & time
- `ST.I2.1.1.2` Attach rooms/invigilation staff

##### `T.I2.1.2` — Conflict Checking

**Sub-Tasks:**

- `ST.I2.1.2.1` Detect student timetable clashes
- `ST.I2.1.2.2` Detect invigilator conflicts

**Suggested DB Tables for `I2` — Exam Timetable Scheduling:**

- `exam_timetable_scheduling_master`
- `exam_timetable_scheduling_transactions`
- `exam_timetable_scheduling_logs`

**Key API Endpoints for `I2`:**

```
GET    /api/v1/timetable-setup           # List / index
POST   /api/v1/timetable-setup           # Create
GET    /api/v1/timetable-setup/{id}    # Show
PUT    /api/v1/timetable-setup/{id}    # Update
DELETE /api/v1/timetable-setup/{id}    # Delete
```

### I3: Marks Entry & Verification

**Status:** 🔄 In-Progress 70%

#### `F.I3.1` — Marks Entry

##### `T.I3.1.1` — Enter Marks

**Sub-Tasks:**

- `ST.I3.1.1.1` Enter marks per student
- `ST.I3.1.1.2` Support grade-only mode

##### `T.I3.1.2` — Bulk Upload

**Sub-Tasks:**

- `ST.I3.1.2.1` Upload marks via Excel template
- `ST.I3.1.2.2` Validate data before import

#### `F.I3.2` — Marks Verification

##### `T.I3.2.1` — Verify Marks

**Sub-Tasks:**

- `ST.I3.2.1.1` Cross-check marks entered
- `ST.I3.2.1.2` Flag discrepancies

**Suggested DB Tables for `I3` — Marks Entry & Verification:**

- `exam_marks`
- `marks_verification_log`

**Key API Endpoints for `I3`:**

```
GET    /api/v1/marks-entry           # List / index
POST   /api/v1/marks-entry           # Create
GET    /api/v1/marks-entry/{id}    # Show
PUT    /api/v1/marks-entry/{id}    # Update
DELETE /api/v1/marks-entry/{id}    # Delete
GET    /api/v1/marks-verification           # List / index
POST   /api/v1/marks-verification           # Create
GET    /api/v1/marks-verification/{id}    # Show
PUT    /api/v1/marks-verification/{id}    # Update
DELETE /api/v1/marks-verification/{id}    # Delete
```

### I4: Moderation Workflow

**Status:** 🔄 In-Progress 70%

#### `F.I4.1` — Moderation Review

##### `T.I4.1.1` — Review Marks

**Sub-Tasks:**

- `ST.I4.1.1.1` Review marks of borderline students
- `ST.I4.1.1.2` Suggest moderated marks

##### `T.I4.1.2` — Moderation Approval

**Sub-Tasks:**

- `ST.I4.1.2.1` Approve/Reject moderation
- `ST.I4.1.2.2` Record remarks with audit trail

**Suggested DB Tables for `I4` — Moderation Workflow:**

- `moderation_workflow_master`
- `moderation_workflow_transactions`
- `moderation_workflow_logs`

**Key API Endpoints for `I4`:**

```
GET    /api/v1/moderation-review           # List / index
POST   /api/v1/moderation-review           # Create
GET    /api/v1/moderation-review/{id}    # Show
PUT    /api/v1/moderation-review/{id}    # Update
DELETE /api/v1/moderation-review/{id}    # Delete
```

### I5: Gradebook Calculation Engine

**Status:** 🔄 In-Progress 50%

#### `F.I5.1` — Grade Calculation

##### `T.I5.1.1` — Calculate Grades

**Sub-Tasks:**

- `ST.I5.1.1.1` Apply grade formula
- `ST.I5.1.1.2` Compute GPA/CGPA

##### `T.I5.1.2` — Special Cases

**Sub-Tasks:**

- `ST.I5.1.2.1` Process absent students
- `ST.I5.1.2.2` Apply grace marks

**Suggested DB Tables for `I5` — Gradebook Calculation Engine:**

- `student_grades`
- `grade_rules`
- `grade_letters`

**Key API Endpoints for `I5`:**

```
GET    /api/v1/grade-calculation           # List / index
POST   /api/v1/grade-calculation           # Create
GET    /api/v1/grade-calculation/{id}    # Show
PUT    /api/v1/grade-calculation/{id}    # Update
DELETE /api/v1/grade-calculation/{id}    # Delete
```

### I6: Report Cards & Publishing

**Status:** ⬜ Not Started

#### `F.I6.1` — Report Generation

##### `T.I6.1.1` — Generate Report Cards

**Sub-Tasks:**

- `ST.I6.1.1.1` Generate PDF report card
- `ST.I6.1.1.2` Apply school branding/templates

##### `T.I6.1.2` — Multi-lingual Reports

**Sub-Tasks:**

- `ST.I6.1.2.1` Enable bilingual report cards
- `ST.I6.1.2.2` Apply regional formatting

#### `F.I6.2` — Publishing

##### `T.I6.2.1` — Publish Results

**Sub-Tasks:**

- `ST.I6.2.1.1` Push reports to parent app
- `ST.I6.2.1.2` Enable download access

**Suggested DB Tables for `I6` — Report Cards & Publishing:**

- `report_card_templates`
- `student_report_cards`
- `report_card_configs`

**Key API Endpoints for `I6`:**

```
GET    /api/v1/report-generation           # List / index
POST   /api/v1/report-generation           # Create
GET    /api/v1/report-generation/{id}    # Show
PUT    /api/v1/report-generation/{id}    # Update
DELETE /api/v1/report-generation/{id}    # Delete
GET    /api/v1/publishing           # List / index
POST   /api/v1/publishing           # Create
GET    /api/v1/publishing/{id}    # Show
PUT    /api/v1/publishing/{id}    # Update
DELETE /api/v1/publishing/{id}    # Delete
```

### I7: Promotion & Detention Rules

**Status:** 🔄 In-Progress 50%

#### `F.I7.1` — Promotion Processing

##### `T.I7.1.1` — Generate Promotion List

**Sub-Tasks:**

- `ST.I7.1.1.1` Apply school promotion rules
- `ST.I7.1.1.2` Identify students for retention

#### `F.I7.2` — Detention Workflow

##### `T.I7.2.1` — Record Detention

**Sub-Tasks:**

- `ST.I7.2.1.1` Mark student as detained
- `ST.I7.2.1.2` Send notification to parents

**Suggested DB Tables for `I7` — Promotion & Detention Rules:**

- `student_promotions`
- `alumni_records`
- `transfer_certificates`

**Key API Endpoints for `I7`:**

```
GET    /api/v1/promotion-processing           # List / index
POST   /api/v1/promotion-processing           # Create
GET    /api/v1/promotion-processing/{id}    # Show
PUT    /api/v1/promotion-processing/{id}    # Update
DELETE /api/v1/promotion-processing/{id}    # Delete
GET    /api/v1/detention-workflow           # List / index
POST   /api/v1/detention-workflow           # Create
GET    /api/v1/detention-workflow/{id}    # Show
PUT    /api/v1/detention-workflow/{id}    # Update
DELETE /api/v1/detention-workflow/{id}    # Delete
```

### I8: Board Pattern Support (CBSE/ICSE/IB/Cambridge)

**Status:** 🔄 In-Progress 80%

#### `F.I8.1` — Board Templates

##### `T.I8.1.1` — Generate Board Report

**Sub-Tasks:**

- `ST.I8.1.1.1` Apply CBSE format
- `ST.I8.1.1.2` Apply ICSE/IB/Cambridge templates

#### `F.I8.2` — Board Mapping

##### `T.I8.2.1` — Map Subjects

**Sub-Tasks:**

- `ST.I8.2.1.1` Map school subjects to board codes
- `ST.I8.2.1.2` Auto-validate board requirements

**Suggested DB Tables for `I8` — Board Pattern Support (CBSE/ICSE/IB/Cambridge):**

- `board_pattern_support_(cbse_ic_master`
- `board_pattern_support_(cbse_ic_transactions`
- `board_pattern_support_(cbse_ic_logs`

**Key API Endpoints for `I8`:**

```
GET    /api/v1/board-templates           # List / index
POST   /api/v1/board-templates           # Create
GET    /api/v1/board-templates/{id}    # Show
PUT    /api/v1/board-templates/{id}    # Update
DELETE /api/v1/board-templates/{id}    # Delete
GET    /api/v1/board-mapping           # List / index
POST   /api/v1/board-mapping           # Create
GET    /api/v1/board-mapping/{id}    # Show
PUT    /api/v1/board-mapping/{id}    # Update
DELETE /api/v1/board-mapping/{id}    # Delete
```

### I9: Custom Report Card Designer

**Status:** 🔄 In-Progress 40%

#### `F.I9.1` — Template Designer

##### `T.I9.1.1` — Design Template

**Sub-Tasks:**

- `ST.I9.1.1.1` Drag & drop fields
- `ST.I9.1.1.2` Set colors/fonts/borders

##### `T.I9.1.2` — Template Management

**Sub-Tasks:**

- `ST.I9.1.2.1` Save template version
- `ST.I9.1.2.2` Assign template to class

**Suggested DB Tables for `I9` — Custom Report Card Designer:**

- `report_card_templates`
- `student_report_cards`
- `report_card_configs`

**Key API Endpoints for `I9`:**

```
GET    /api/v1/template-designer           # List / index
POST   /api/v1/template-designer           # Create
GET    /api/v1/template-designer/{id}    # Show
PUT    /api/v1/template-designer/{id}    # Update
DELETE /api/v1/template-designer/{id}    # Delete
```

### Screen Design Requirements — Module I


### Report Requirements — Module I

- **Report Generation**: Tabular report with date range filter, export to PDF/Excel/CSV

### Test Case Requirements — Module I

| Test Type | Scope |
|---|---|
| **Unit Tests** | All service classes and model methods in Module I |
| **Feature Tests** | All API endpoints — happy path, validation errors, auth failures |
| **Browser Tests** | Form submissions, list pagination, filter/search, export |
| **Functional Tests** | End-to-end business workflows (e.g., create → approve → complete lifecycle) |

---

## Module J: Fees & Finance Management

| | |
|---|---|
| **Module Code** | `J` |
| **App Type** | Both |
| **Description** | Fee structures, student billing, collections, concessions, transport/hostel fees, fines, outstanding, analytics. |
| **Total Sub-Modules** | 10 |
| **Total Features (Tasks)** | 28 |
| **Total Sub-Tasks** | 57 |

### Sub-Module Status

| Sub-Mod Code | Sub-Module Name | App Type | Status |
|---|---|---|---|
| `J1` | Fee Structure & Components | Both | ✅ Completed 100% |
| `J10` | Dynamic Fee Structure Engine | Both | ⬜ Not Started |
| `J2` | Student Fee Assignment | Both | ✅ Completed 100% |
| `J3` | Fee Collection & Receipts | Both | ✅ Completed 100% |
| `J4` | Fee Concessions & Discounts | Both | ✅ Completed 100% |
| `J5` | Transport & Hostel Fee Management | Both | ✅ Completed 100% |
| `J6` | Fine, Penalty & Waiver Management | Both | ✅ Completed 100% |
| `J7` | Outstanding & Dues Management | Both | ✅ Completed 100% |
| `J8` | Fee Reports & Analytics | Both | ✅ Completed 100% |
| `J9` | Financial Aid & Scholarship Management | Both | ⬜ Not Started |

### J1: Fee Structure & Components

**Status:** ✅ Completed 100%

#### `F.J1.1` — Fee Heads

##### `T.J1.1.1` — Create Fee Head

**Sub-Tasks:**

- `ST.J1.1.1.1` Define fee head name (Tuition, Transport, Hostel)
- `ST.J1.1.1.2` Assign ledger mapping
- `ST.J1.1.1.3` Set tax applicability

##### `T.J1.1.2` — Manage Fee Head Groups

**Sub-Tasks:**

- `ST.J1.1.2.1` Create fee group (Academic, Transport)
- `ST.J1.1.2.2` Assign fee heads to group

#### `F.J1.2` — Fee Templates

##### `T.J1.2.1` — Create Fee Structure

**Sub-Tasks:**

- `ST.J1.2.1.1` Define class-wise fee amount
- `ST.J1.2.1.2` Map optional/mandatory heads

##### `T.J1.2.2` — Installment Setup

**Sub-Tasks:**

- `ST.J1.2.2.1` Define installment dates
- `ST.J1.2.2.2` Set fine rules

**Suggested DB Tables for `J1` — Fee Structure & Components:**

- `fee_heads`
- `fee_groups`
- `fee_templates`
- `fee_installments`

**Key API Endpoints for `J1`:**

```
GET    /api/v1/fee-heads           # List / index
POST   /api/v1/fee-heads           # Create
GET    /api/v1/fee-heads/{id}    # Show
PUT    /api/v1/fee-heads/{id}    # Update
DELETE /api/v1/fee-heads/{id}    # Delete
GET    /api/v1/fee-templates           # List / index
POST   /api/v1/fee-templates           # Create
GET    /api/v1/fee-templates/{id}    # Show
PUT    /api/v1/fee-templates/{id}    # Update
DELETE /api/v1/fee-templates/{id}    # Delete
```

### J10: Dynamic Fee Structure Engine

**Status:** ⬜ Not Started

#### `F.J10.1` — Fee Rule Builder

##### `T.J10.1.1` — Create Fee Rules

**Sub-Tasks:**

- `ST.J10.1.1.1` Define rules based on student attributes (Class, Category, Board)
- `ST.J10.1.1.2` Set conditional logic (e.g., sibling discount if 2+ students)

##### `T.J10.1.2` — Rule Testing & Simulation

**Sub-Tasks:**

- `ST.J10.1.2.1` Test fee calculation for sample student profiles
- `ST.J10.1.2.2` Preview fee breakdown before applying to batch

**Suggested DB Tables for `J10` — Dynamic Fee Structure Engine:**

- `fee_heads`
- `fee_groups`
- `fee_templates`
- `fee_installments`

**Key API Endpoints for `J10`:**

```
GET    /api/v1/fee-rule-builder           # List / index
POST   /api/v1/fee-rule-builder           # Create
GET    /api/v1/fee-rule-builder/{id}    # Show
PUT    /api/v1/fee-rule-builder/{id}    # Update
DELETE /api/v1/fee-rule-builder/{id}    # Delete
```

### J2: Student Fee Assignment

**Status:** ✅ Completed 100%

#### `F.J2.1` — Fee Allocation

##### `T.J2.1.1` — Assign Fees to Student

**Sub-Tasks:**

- `ST.J2.1.1.1` Auto-assign class-wise fees
- `ST.J2.1.1.2` Apply concession/scholarship

##### `T.J2.1.2` — Bulk Fee Allocation

**Sub-Tasks:**

- `ST.J2.1.2.1` Upload CSV for mass assignment
- `ST.J2.1.2.2` Validate student-class mapping

#### `F.J2.2` — Optional Fee Management

##### `T.J2.2.1` — Elective Fee Assignment

**Sub-Tasks:**

- `ST.J2.2.1.1` Select optional fee heads
- `ST.J2.2.1.2` Apply prorated amount

**Suggested DB Tables for `J2` — Student Fee Assignment:**

- `student_fees`
- `student_fee_allocations`

**Key API Endpoints for `J2`:**

```
GET    /api/v1/fee-allocation           # List / index
POST   /api/v1/fee-allocation           # Create
GET    /api/v1/fee-allocation/{id}    # Show
PUT    /api/v1/fee-allocation/{id}    # Update
DELETE /api/v1/fee-allocation/{id}    # Delete
GET    /api/v1/optional-fee-management           # List / index
POST   /api/v1/optional-fee-management           # Create
GET    /api/v1/optional-fee-management/{id}    # Show
PUT    /api/v1/optional-fee-management/{id}    # Update
DELETE /api/v1/optional-fee-management/{id}    # Delete
```

### J3: Fee Collection & Receipts

**Status:** ✅ Completed 100%

#### `F.J3.1` — Collection Entry

##### `T.J3.1.1` — Record Fee Payment

**Sub-Tasks:**

- `ST.J3.1.1.1` Select payment mode (Cash/UPI/Bank)
- `ST.J3.1.1.2` Enter amount & receipt details

##### `T.J3.1.2` — Auto Receipt Generation

**Sub-Tasks:**

- `ST.J3.1.2.1` Generate receipt number
- `ST.J3.1.2.2` Send SMS/email confirmation

#### `F.J3.2` — Online Payments

##### `T.J3.2.1` — Gateway Integration

**Sub-Tasks:**

- `ST.J3.2.1.1` Integrate with Razorpay/Paytm
- `ST.J3.2.1.2` Auto-reconcile online payments

**Suggested DB Tables for `J3` — Fee Collection & Receipts:**

- `fee_payments`
- `fee_receipts`
- `payment_gateways`

**Key API Endpoints for `J3`:**

```
GET    /api/v1/collection-entry           # List / index
POST   /api/v1/collection-entry           # Create
GET    /api/v1/collection-entry/{id}    # Show
PUT    /api/v1/collection-entry/{id}    # Update
DELETE /api/v1/collection-entry/{id}    # Delete
GET    /api/v1/online-payments           # List / index
POST   /api/v1/online-payments           # Create
GET    /api/v1/online-payments/{id}    # Show
PUT    /api/v1/online-payments/{id}    # Update
DELETE /api/v1/online-payments/{id}    # Delete
```

### J4: Fee Concessions & Discounts

**Status:** ✅ Completed 100%

#### `F.J4.1` — Concession Rules

##### `T.J4.1.1` — Create Concession

**Sub-Tasks:**

- `ST.J4.1.1.1` Define concession type (Sibling, Merit)
- `ST.J4.1.1.2` Set percentage/amount

##### `T.J4.1.2` — Approve Concession

**Sub-Tasks:**

- `ST.J4.1.2.1` Send approval request
- `ST.J4.1.2.2` Record approval history

**Suggested DB Tables for `J4` — Fee Concessions & Discounts:**

- `fee_concessions`
- `concession_rules`
- `concession_approvals`

**Key API Endpoints for `J4`:**

```
GET    /api/v1/concession-rules           # List / index
POST   /api/v1/concession-rules           # Create
GET    /api/v1/concession-rules/{id}    # Show
PUT    /api/v1/concession-rules/{id}    # Update
DELETE /api/v1/concession-rules/{id}    # Delete
```

### J5: Transport & Hostel Fee Management

**Status:** ✅ Completed 100%

#### `F.J5.1` — Transport Fees

##### `T.J5.1.1` — Assign Route Fee

**Sub-Tasks:**

- `ST.J5.1.1.1` Select route & stop
- `ST.J5.1.1.2` Auto-calculate monthly fee

##### `T.J5.1.2` — Transport Adjustment

**Sub-Tasks:**

- `ST.J5.1.2.1` Handle mid-session stop change
- `ST.J5.1.2.2` Apply pro-rata calculation

#### `F.J5.2` — Hostel Fees

##### `T.J5.2.1` — Assign Hostel Fee

**Sub-Tasks:**

- `ST.J5.2.1.1` Assign room type
- `ST.J5.2.1.2` Apply mess charges

##### `T.J5.2.2` — Hostel Adjustment

**Sub-Tasks:**

- `ST.J5.2.2.1` Partial month calculation
- `ST.J5.2.2.2` Room change adjustment

**Suggested DB Tables for `J5` — Transport & Hostel Fee Management:**

- `transport_routes`
- `route_stops`
- `vehicles`
- `drivers`
- `student_transports`

**Key API Endpoints for `J5`:**

```
GET    /api/v1/transport-fees           # List / index
POST   /api/v1/transport-fees           # Create
GET    /api/v1/transport-fees/{id}    # Show
PUT    /api/v1/transport-fees/{id}    # Update
DELETE /api/v1/transport-fees/{id}    # Delete
GET    /api/v1/hostel-fees           # List / index
POST   /api/v1/hostel-fees           # Create
GET    /api/v1/hostel-fees/{id}    # Show
PUT    /api/v1/hostel-fees/{id}    # Update
DELETE /api/v1/hostel-fees/{id}    # Delete
```

### J6: Fine, Penalty & Waiver Management

**Status:** ✅ Completed 100%

#### `F.J6.1` — Fine Rules

##### `T.J6.1.1` — Set Fine Rule

**Sub-Tasks:**

- `ST.J6.1.1.1` Define late fee per day
- `ST.J6.1.1.2` Set grace period

#### `F.J6.2` — Waiver Processing

##### `T.J6.2.1` — Approve Waiver

**Sub-Tasks:**

- `ST.J6.2.1.1` Record waiver reason
- `ST.J6.2.1.2` Generate approval log

**Suggested DB Tables for `J6` — Fine, Penalty & Waiver Management:**

- `fine,_penalty_waiver_managemen_master`
- `fine,_penalty_waiver_managemen_transactions`
- `fine,_penalty_waiver_managemen_logs`

**Key API Endpoints for `J6`:**

```
GET    /api/v1/fine-rules           # List / index
POST   /api/v1/fine-rules           # Create
GET    /api/v1/fine-rules/{id}    # Show
PUT    /api/v1/fine-rules/{id}    # Update
DELETE /api/v1/fine-rules/{id}    # Delete
GET    /api/v1/waiver-processing           # List / index
POST   /api/v1/waiver-processing           # Create
GET    /api/v1/waiver-processing/{id}    # Show
PUT    /api/v1/waiver-processing/{id}    # Update
DELETE /api/v1/waiver-processing/{id}    # Delete
```

### J7: Outstanding & Dues Management

**Status:** ✅ Completed 100%

#### `F.J7.1` — Dues Tracking

##### `T.J7.1.1` — Calculate Outstanding

**Sub-Tasks:**

- `ST.J7.1.1.1` Compute fee pending per student
- `ST.J7.1.1.2` Identify overdue installments

##### `T.J7.1.2` — Auto-Alerts

**Sub-Tasks:**

- `ST.J7.1.2.1` Send due reminders
- `ST.J7.1.2.2` Escalate to admin after multiple misses

**Suggested DB Tables for `J7` — Outstanding & Dues Management:**

- `outstanding_dues_management_master`
- `outstanding_dues_management_transactions`
- `outstanding_dues_management_logs`

**Key API Endpoints for `J7`:**

```
GET    /api/v1/dues-tracking           # List / index
POST   /api/v1/dues-tracking           # Create
GET    /api/v1/dues-tracking/{id}    # Show
PUT    /api/v1/dues-tracking/{id}    # Update
DELETE /api/v1/dues-tracking/{id}    # Delete
```

### J8: Fee Reports & Analytics

**Status:** ✅ Completed 100%

#### `F.J8.1` — Standard Reports

##### `T.J8.1.1` — Generate Reports

**Sub-Tasks:**

- `ST.J8.1.1.1` Fee collection summary
- `ST.J8.1.1.2` Outstanding report

#### `F.J8.2` — Advanced Analytics

##### `T.J8.2.1` — AI-based Predictions

**Sub-Tasks:**

- `ST.J8.2.1.1` Predict fee default risk
- `ST.J8.2.1.2` Identify patterns in late payments

**Suggested DB Tables for `J8` — Fee Reports & Analytics:**

- `ml_model_configs`
- `prediction_results`
- `analytics_snapshots`

**Key API Endpoints for `J8`:**

```
GET    /api/v1/standard-reports           # List / index
POST   /api/v1/standard-reports           # Create
GET    /api/v1/standard-reports/{id}    # Show
PUT    /api/v1/standard-reports/{id}    # Update
DELETE /api/v1/standard-reports/{id}    # Delete
GET    /api/v1/advanced-analytics           # List / index
POST   /api/v1/advanced-analytics           # Create
GET    /api/v1/advanced-analytics/{id}    # Show
PUT    /api/v1/advanced-analytics/{id}    # Update
DELETE /api/v1/advanced-analytics/{id}    # Delete
```

### J9: Financial Aid & Scholarship Management

**Status:** ⬜ Not Started

#### `F.J9.1` — Scholarship Fund Setup

##### `T.J9.1.1` — Create Scholarship Fund

**Sub-Tasks:**

- `ST.J9.1.1.1` Define fund name, sponsor, and total amount
- `ST.J9.1.1.2` Set eligibility criteria (Academic, Financial Need, Category)

##### `T.J9.1.2` — Application Workflow

**Sub-Tasks:**

- `ST.J9.1.2.1` Create online scholarship application form
- `ST.J9.1.2.2` Define review committee and approval stages

#### `F.J9.2` — Disbursement & Tracking

##### `T.J9.2.1` — Approve & Disburse

**Sub-Tasks:**

- `ST.J9.2.1.1` Approve applications and allocate amounts
- `ST.J9.2.1.2` Auto-apply scholarship to student fee account

##### `T.J9.2.2` — Renewal Management

**Sub-Tasks:**

- `ST.J9.2.2.1` Track renewal criteria (e.g., maintain certain grades)
- `ST.J9.2.2.2` Send renewal reminders and process continuations

**Suggested DB Tables for `J9` — Financial Aid & Scholarship Management:**

- `financial_aid_scholarship_mana_master`
- `financial_aid_scholarship_mana_transactions`
- `financial_aid_scholarship_mana_logs`

**Key API Endpoints for `J9`:**

```
GET    /api/v1/scholarship-fund-setup           # List / index
POST   /api/v1/scholarship-fund-setup           # Create
GET    /api/v1/scholarship-fund-setup/{id}    # Show
PUT    /api/v1/scholarship-fund-setup/{id}    # Update
DELETE /api/v1/scholarship-fund-setup/{id}    # Delete
GET    /api/v1/disbursement---tracking           # List / index
POST   /api/v1/disbursement---tracking           # Create
GET    /api/v1/disbursement---tracking/{id}    # Show
PUT    /api/v1/disbursement---tracking/{id}    # Update
DELETE /api/v1/disbursement---tracking/{id}    # Delete
```

### Screen Design Requirements — Module J


### Report Requirements — Module J

- **Standard Reports**: Tabular report with date range filter, export to PDF/Excel/CSV
- **Advanced Analytics**: Tabular report with date range filter, export to PDF/Excel/CSV

### Test Case Requirements — Module J

| Test Type | Scope |
|---|---|
| **Unit Tests** | All service classes and model methods in Module J |
| **Feature Tests** | All API endpoints — happy path, validation errors, auth failures |
| **Browser Tests** | Form submissions, list pagination, filter/search, export |
| **Functional Tests** | End-to-end business workflows (e.g., create → approve → complete lifecycle) |

---

## Module K: Finance & Accounting

| | |
|---|---|
| **Module Code** | `K` |
| **App Type** | Both |
| **Description** | Full double-entry accounting — COA, journals, AR/AP, bank reconciliation, asset depreciation, GST, Tally integration. |
| **Total Sub-Modules** | 13 |
| **Total Features (Tasks)** | 34 |
| **Total Sub-Tasks** | 70 |

### Sub-Module Status

| Sub-Mod Code | Sub-Module Name | App Type | Status |
|---|---|---|---|
| `K1` | Chart of Accounts (COA) | Both | ⬜ Pending |
| `K10` | Financial Reporting | Both | ⬜ Pending |
| `K11` | Integrations (Tally/QuickBooks) | Both | ⬜ Pending |
| `K12` | Budget & Cost Center Management | Both | ⬜ Not Started |
| `K13` | GST & Tax Compliance Engine | Both | ⬜ Not Started |
| `K2` | Opening Balances | Both | ⬜ Pending |
| `K3` | Journal Entry Management | Both | ⬜ Pending |
| `K4` | Accounts Receivable (AR) | Both | ⬜ Pending |
| `K5` | Accounts Payable (AP) | Both | ⬜ Pending |
| `K6` | Vendor Management | Both | ⬜ Pending |
| `K7` | Purchase & Expense Management | Both | ⬜ Pending |
| `K8` | Bank & Cash Management | Both | ⬜ Pending |
| `K9` | Asset Register & Depreciation | Both | ⬜ Pending |

### K1: Chart of Accounts (COA)

**Status:** ⬜ Pending

#### `F.K1.1` — Account Groups

##### `T.K1.1.1` — Create Account Group

**Sub-Tasks:**

- `ST.K1.1.1.1` Define primary group (Assets/Liabilities/Income/Expense)
- `ST.K1.1.1.2` Assign accounting nature (Debit/Credit)

##### `T.K1.1.2` — Manage Sub-Groups

**Sub-Tasks:**

- `ST.K1.1.2.1` Create hierarchical sub-groups
- `ST.K1.1.2.2` Set posting permissions

#### `F.K1.2` — Ledger Management

##### `T.K1.2.1` — Create Ledger

**Sub-Tasks:**

- `ST.K1.2.1.1` Define ledger name & code
- `ST.K1.2.1.2` Assign parent account group
- `ST.K1.2.1.3` Link GST/TAX configuration

##### `T.K1.2.2` — Ledger Settings

**Sub-Tasks:**

- `ST.K1.2.2.1` Enable reconciliation
- `ST.K1.2.2.2` Set allowed modules for ledger usage

**Suggested DB Tables for `K1` — Chart of Accounts (COA):**

- `account_groups`
- `ledgers`
- `ledger_opening_balances`

**Key API Endpoints for `K1`:**

```
GET    /api/v1/account-groups           # List / index
POST   /api/v1/account-groups           # Create
GET    /api/v1/account-groups/{id}    # Show
PUT    /api/v1/account-groups/{id}    # Update
DELETE /api/v1/account-groups/{id}    # Delete
GET    /api/v1/ledger-management           # List / index
POST   /api/v1/ledger-management           # Create
GET    /api/v1/ledger-management/{id}    # Show
PUT    /api/v1/ledger-management/{id}    # Update
DELETE /api/v1/ledger-management/{id}    # Delete
```

### K10: Financial Reporting

**Status:** ⬜ Pending

#### `F.K10.1` — Standard Reports

##### `T.K10.1.1` — Generate Reports

**Sub-Tasks:**

- `ST.K10.1.1.1` Trial Balance
- `ST.K10.1.1.2` Profit & Loss
- `ST.K10.1.1.3` Balance Sheet

#### `F.K10.2` — Dashboards

##### `T.K10.2.1` — Finance Dashboard

**Sub-Tasks:**

- `ST.K10.2.1.1` Revenue vs Expense analysis
- `ST.K10.2.1.2` Cashflow trend visualization

**Suggested DB Tables for `K10` — Financial Reporting:**

- `financial_reporting_master`
- `financial_reporting_transactions`
- `financial_reporting_logs`

**Key API Endpoints for `K10`:**

```
GET    /api/v1/standard-reports           # List / index
POST   /api/v1/standard-reports           # Create
GET    /api/v1/standard-reports/{id}    # Show
PUT    /api/v1/standard-reports/{id}    # Update
DELETE /api/v1/standard-reports/{id}    # Delete
GET    /api/v1/dashboards           # List / index
POST   /api/v1/dashboards           # Create
GET    /api/v1/dashboards/{id}    # Show
PUT    /api/v1/dashboards/{id}    # Update
DELETE /api/v1/dashboards/{id}    # Delete
```

### K11: Integrations (Tally/QuickBooks)

**Status:** ⬜ Pending

#### `F.K11.1` — Tally Integration

##### `T.K11.1.1` — Export Vouchers

**Sub-Tasks:**

- `ST.K11.1.1.1` Export JE/Receipts in XML
- `ST.K11.1.1.2` Download Tally-compatible files

#### `F.K11.2` — QuickBooks/Zoho

##### `T.K11.2.1` — Sync Accounts

**Sub-Tasks:**

- `ST.K11.2.1.1` Synchronize ledgers
- `ST.K11.2.1.2` Sync transactions via API

**Suggested DB Tables for `K11` — Integrations (Tally/QuickBooks):**

- `books`
- `book_copies`
- `library_members`
- `book_issues`

**Key API Endpoints for `K11`:**

```
GET    /api/v1/tally-integration           # List / index
POST   /api/v1/tally-integration           # Create
GET    /api/v1/tally-integration/{id}    # Show
PUT    /api/v1/tally-integration/{id}    # Update
DELETE /api/v1/tally-integration/{id}    # Delete
GET    /api/v1/quickbooks-zoho           # List / index
POST   /api/v1/quickbooks-zoho           # Create
GET    /api/v1/quickbooks-zoho/{id}    # Show
PUT    /api/v1/quickbooks-zoho/{id}    # Update
DELETE /api/v1/quickbooks-zoho/{id}    # Delete
```

### K12: Budget & Cost Center Management

**Status:** ⬜ Not Started

#### `F.K12.1` — Budget Creation

##### `T.K12.1.1` — Define Fiscal Year Budget

**Sub-Tasks:**

- `ST.K12.1.1.1` Set overall institutional budget for the fiscal year
- `ST.K12.1.1.2` Allocate budgets to departments/cost centers (Academics, Sports, Admin)

##### `T.K12.1.2` — Budget Tracking

**Sub-Tasks:**

- `ST.K12.1.2.1` Record commitments (POs) and actual expenditures against budget
- `ST.K12.1.2.2` Calculate available balance per cost center in real-time

#### `F.K12.2` — Budget Reports

##### `T.K12.2.1` — Generate Variance Reports

**Sub-Tasks:**

- `ST.K12.2.1.1` Show budget vs. actual spend with variance percentages
- `ST.K12.2.1.2` Highlight departments exceeding budget thresholds

**Suggested DB Tables for `K12` — Budget & Cost Center Management:**

- `budget_cost_center_management_master`
- `budget_cost_center_management_transactions`
- `budget_cost_center_management_logs`

**Key API Endpoints for `K12`:**

```
GET    /api/v1/budget-creation           # List / index
POST   /api/v1/budget-creation           # Create
GET    /api/v1/budget-creation/{id}    # Show
PUT    /api/v1/budget-creation/{id}    # Update
DELETE /api/v1/budget-creation/{id}    # Delete
GET    /api/v1/budget-reports           # List / index
POST   /api/v1/budget-reports           # Create
GET    /api/v1/budget-reports/{id}    # Show
PUT    /api/v1/budget-reports/{id}    # Update
DELETE /api/v1/budget-reports/{id}    # Delete
```

### K13: GST & Tax Compliance Engine

**Status:** ⬜ Not Started

#### `F.K13.1` — GST Configuration

##### `T.K13.1.1` — Setup Tax Rules

**Sub-Tasks:**

- `ST.K13.1.1.1` Define HSN/SAC codes for fee heads and services
- `ST.K13.1.1.2` Configure tax rates (CGST, SGST, IGST) based on location

##### `T.K13.1.2` — E-Invoicing Integration

**Sub-Tasks:**

- `ST.K13.1.2.1` Generate IRN (Invoice Reference Number) via government portal
- `ST.K13.1.2.2` Attach QR code to invoices for verification

#### `F.K13.2` — GST Return Preparation

##### `T.K13.2.1` — Generate GSTR Reports

**Sub-Tasks:**

- `ST.K13.2.1.1` Compile data for GSTR-1 (Outward supplies)
- `ST.K13.2.1.2` Compile data for GSTR-3B (Summary return)

**Suggested DB Tables for `K13` — GST & Tax Compliance Engine:**

- `pf_esi_configs`
- `statutory_reports`

**Key API Endpoints for `K13`:**

```
GET    /api/v1/gst-configuration           # List / index
POST   /api/v1/gst-configuration           # Create
GET    /api/v1/gst-configuration/{id}    # Show
PUT    /api/v1/gst-configuration/{id}    # Update
DELETE /api/v1/gst-configuration/{id}    # Delete
GET    /api/v1/gst-return-preparation           # List / index
POST   /api/v1/gst-return-preparation           # Create
GET    /api/v1/gst-return-preparation/{id}    # Show
PUT    /api/v1/gst-return-preparation/{id}    # Update
DELETE /api/v1/gst-return-preparation/{id}    # Delete
```

### K2: Opening Balances

**Status:** ⬜ Pending

#### `F.K2.1` — Ledger Opening

##### `T.K2.1.1` — Add Opening Balances

**Sub-Tasks:**

- `ST.K2.1.1.1` Enter debit/credit opening balance
- `ST.K2.1.1.2` Validate fiscal year constraints

#### `F.K2.2` — Student & Vendor Opening

##### `T.K2.2.1` — Import Openings

**Sub-Tasks:**

- `ST.K2.2.1.1` Upload outstanding fee CSV
- `ST.K2.2.1.2` Map vendor outstanding balances

**Suggested DB Tables for `K2` — Opening Balances:**

- `opening_balances_master`
- `opening_balances_transactions`
- `opening_balances_logs`

**Key API Endpoints for `K2`:**

```
GET    /api/v1/ledger-opening           # List / index
POST   /api/v1/ledger-opening           # Create
GET    /api/v1/ledger-opening/{id}    # Show
PUT    /api/v1/ledger-opening/{id}    # Update
DELETE /api/v1/ledger-opening/{id}    # Delete
GET    /api/v1/student---vendor-opening           # List / index
POST   /api/v1/student---vendor-opening           # Create
GET    /api/v1/student---vendor-opening/{id}    # Show
PUT    /api/v1/student---vendor-opening/{id}    # Update
DELETE /api/v1/student---vendor-opening/{id}    # Delete
```

### K3: Journal Entry Management

**Status:** ⬜ Pending

#### `F.K3.1` — Manual Journals

##### `T.K3.1.1` — Create Journal Entry

**Sub-Tasks:**

- `ST.K3.1.1.1` Select debit/credit ledgers
- `ST.K3.1.1.2` Add narration & attachments

##### `T.K3.1.2` — Approval Workflow

**Sub-Tasks:**

- `ST.K3.1.2.1` Submit JE for approval
- `ST.K3.1.2.2` Track approval history

#### `F.K3.2` — Recurring Journals

##### `T.K3.2.1` — Setup Recurring JE

**Sub-Tasks:**

- `ST.K3.2.1.1` Define recurrence cycle
- `ST.K3.2.1.2` Auto-post according to period

**Suggested DB Tables for `K3` — Journal Entry Management:**

- `journal_entries`
- `journal_entry_items`

**Key API Endpoints for `K3`:**

```
GET    /api/v1/manual-journals           # List / index
POST   /api/v1/manual-journals           # Create
GET    /api/v1/manual-journals/{id}    # Show
PUT    /api/v1/manual-journals/{id}    # Update
DELETE /api/v1/manual-journals/{id}    # Delete
GET    /api/v1/recurring-journals           # List / index
POST   /api/v1/recurring-journals           # Create
GET    /api/v1/recurring-journals/{id}    # Show
PUT    /api/v1/recurring-journals/{id}    # Update
DELETE /api/v1/recurring-journals/{id}    # Delete
```

### K4: Accounts Receivable (AR)

**Status:** ⬜ Pending

#### `F.K4.1` — Student Receivables

##### `T.K4.1.1` — Auto-Post Fee Invoices

**Sub-Tasks:**

- `ST.K4.1.1.1` Generate fee JE automatically
- `ST.K4.1.1.2` Map fee heads to income ledgers

##### `T.K4.1.2` — Record Payments

**Sub-Tasks:**

- `ST.K4.1.2.1` Accept multi-mode payments
- `ST.K4.1.2.2` Auto-send receipt to parent

#### `F.K4.2` — Aging & Collections

##### `T.K4.2.1` — Generate Aging Reports

**Sub-Tasks:**

- `ST.K4.2.1.1` Produce 30/60/90-day aging
- `ST.K4.2.1.2` Identify high-risk accounts

##### `T.K4.2.2` — Collection Follow-up

**Sub-Tasks:**

- `ST.K4.2.2.1` Send due reminders
- `ST.K4.2.2.2` Escalate chronic defaulters

**Suggested DB Tables for `K4` — Accounts Receivable (AR):**

- `ar_invoices`
- `ar_payments`
- `ar_aging`

**Key API Endpoints for `K4`:**

```
GET    /api/v1/student-receivables           # List / index
POST   /api/v1/student-receivables           # Create
GET    /api/v1/student-receivables/{id}    # Show
PUT    /api/v1/student-receivables/{id}    # Update
DELETE /api/v1/student-receivables/{id}    # Delete
GET    /api/v1/aging---collections           # List / index
POST   /api/v1/aging---collections           # Create
GET    /api/v1/aging---collections/{id}    # Show
PUT    /api/v1/aging---collections/{id}    # Update
DELETE /api/v1/aging---collections/{id}    # Delete
```

### K5: Accounts Payable (AP)

**Status:** ⬜ Pending

#### `F.K5.1` — Vendor Bills

##### `T.K5.1.1` — Enter Vendor Bill

**Sub-Tasks:**

- `ST.K5.1.1.1` Attach bill copy
- `ST.K5.1.1.2` Verify purchase order linkage

#### `F.K5.2` — Vendor Payments

##### `T.K5.2.1` — Process Payment

**Sub-Tasks:**

- `ST.K5.2.1.1` Select payment mode
- `ST.K5.2.1.2` Auto-generate payment voucher

**Suggested DB Tables for `K5` — Accounts Payable (AP):**

- `vendors`
- `vendor_bills`
- `ap_payments`

**Key API Endpoints for `K5`:**

```
GET    /api/v1/vendor-bills           # List / index
POST   /api/v1/vendor-bills           # Create
GET    /api/v1/vendor-bills/{id}    # Show
PUT    /api/v1/vendor-bills/{id}    # Update
DELETE /api/v1/vendor-bills/{id}    # Delete
GET    /api/v1/vendor-payments           # List / index
POST   /api/v1/vendor-payments           # Create
GET    /api/v1/vendor-payments/{id}    # Show
PUT    /api/v1/vendor-payments/{id}    # Update
DELETE /api/v1/vendor-payments/{id}    # Delete
```

### K6: Vendor Management

**Status:** ⬜ Pending

#### `F.K6.1` — Vendor Profiles

##### `T.K6.1.1` — Create Vendor

**Sub-Tasks:**

- `ST.K6.1.1.1` Capture vendor GST/PAN
- `ST.K6.1.1.2` Store contract terms

#### `F.K6.2` — Vendor Rating

##### `T.K6.2.1` — Rate Vendor

**Sub-Tasks:**

- `ST.K6.2.1.1` Rate quality & delivery time
- `ST.K6.2.1.2` Update rating based on performance

**Suggested DB Tables for `K6` — Vendor Management:**

- `vendors`
- `vendor_bills`
- `ap_payments`

**Key API Endpoints for `K6`:**

```
GET    /api/v1/vendor-profiles           # List / index
POST   /api/v1/vendor-profiles           # Create
GET    /api/v1/vendor-profiles/{id}    # Show
PUT    /api/v1/vendor-profiles/{id}    # Update
DELETE /api/v1/vendor-profiles/{id}    # Delete
GET    /api/v1/vendor-rating           # List / index
POST   /api/v1/vendor-rating           # Create
GET    /api/v1/vendor-rating/{id}    # Show
PUT    /api/v1/vendor-rating/{id}    # Update
DELETE /api/v1/vendor-rating/{id}    # Delete
```

### K7: Purchase & Expense Management

**Status:** ⬜ Pending

#### `F.K7.1` — Purchase Orders

##### `T.K7.1.1` — Create PO

**Sub-Tasks:**

- `ST.K7.1.1.1` Select vendor & items
- `ST.K7.1.1.2` Apply tax & discount rules

#### `F.K7.2` — Expense Claims

##### `T.K7.2.1` — Process Claims

**Sub-Tasks:**

- `ST.K7.2.1.1` Upload claim receipts
- `ST.K7.2.1.2` Approve/Reject staff claims

**Suggested DB Tables for `K7` — Purchase & Expense Management:**

- `purchase_expense_management_master`
- `purchase_expense_management_transactions`
- `purchase_expense_management_logs`

**Key API Endpoints for `K7`:**

```
GET    /api/v1/purchase-orders           # List / index
POST   /api/v1/purchase-orders           # Create
GET    /api/v1/purchase-orders/{id}    # Show
PUT    /api/v1/purchase-orders/{id}    # Update
DELETE /api/v1/purchase-orders/{id}    # Delete
GET    /api/v1/expense-claims           # List / index
POST   /api/v1/expense-claims           # Create
GET    /api/v1/expense-claims/{id}    # Show
PUT    /api/v1/expense-claims/{id}    # Update
DELETE /api/v1/expense-claims/{id}    # Delete
```

### K8: Bank & Cash Management

**Status:** ⬜ Pending

#### `F.K8.1` — Bank Reconciliation

##### `T.K8.1.1` — Import Bank Statement

**Sub-Tasks:**

- `ST.K8.1.1.1` Upload CSV/MT940
- `ST.K8.1.1.2` Auto-match transactions

##### `T.K8.1.2` — Reconcile Entries

**Sub-Tasks:**

- `ST.K8.1.2.1` Mark matched items
- `ST.K8.1.2.2` Identify mismatches

#### `F.K8.2` — Cash Register

##### `T.K8.2.1` — Manage Cashbook

**Sub-Tasks:**

- `ST.K8.2.1.1` Record cash inflow/outflow
- `ST.K8.2.1.2` Track daily cash balance

**Suggested DB Tables for `K8` — Bank & Cash Management:**

- `bank_accounts`
- `bank_reconciliations`
- `cash_books`

**Key API Endpoints for `K8`:**

```
GET    /api/v1/bank-reconciliation           # List / index
POST   /api/v1/bank-reconciliation           # Create
GET    /api/v1/bank-reconciliation/{id}    # Show
PUT    /api/v1/bank-reconciliation/{id}    # Update
DELETE /api/v1/bank-reconciliation/{id}    # Delete
GET    /api/v1/cash-register           # List / index
POST   /api/v1/cash-register           # Create
GET    /api/v1/cash-register/{id}    # Show
PUT    /api/v1/cash-register/{id}    # Update
DELETE /api/v1/cash-register/{id}    # Delete
```

### K9: Asset Register & Depreciation

**Status:** ⬜ Pending

#### `F.K9.1` — Asset Register

##### `T.K9.1.1` — Add Asset

**Sub-Tasks:**

- `ST.K9.1.1.1` Enter asset details
- `ST.K9.1.1.2` Assign asset category

#### `F.K9.2` — Depreciation Engine

##### `T.K9.2.1` — Calculate Depreciation

**Sub-Tasks:**

- `ST.K9.2.1.1` Apply SLM/WDV methods
- `ST.K9.2.1.2` Generate depreciation JE

**Suggested DB Tables for `K9` — Asset Register & Depreciation:**

- `fixed_assets`
- `depreciation_schedules`

**Key API Endpoints for `K9`:**

```
GET    /api/v1/asset-register           # List / index
POST   /api/v1/asset-register           # Create
GET    /api/v1/asset-register/{id}    # Show
PUT    /api/v1/asset-register/{id}    # Update
DELETE /api/v1/asset-register/{id}    # Delete
GET    /api/v1/depreciation-engine           # List / index
POST   /api/v1/depreciation-engine           # Create
GET    /api/v1/depreciation-engine/{id}    # Show
PUT    /api/v1/depreciation-engine/{id}    # Update
DELETE /api/v1/depreciation-engine/{id}    # Delete
```

### Screen Design Requirements — Module K


### Report Requirements — Module K

- **Standard Reports**: Tabular report with date range filter, export to PDF/Excel/CSV
- **Budget Reports**: Tabular report with date range filter, export to PDF/Excel/CSV

### Test Case Requirements — Module K

| Test Type | Scope |
|---|---|
| **Unit Tests** | All service classes and model methods in Module K |
| **Feature Tests** | All API endpoints — happy path, validation errors, auth failures |
| **Browser Tests** | Form submissions, list pagination, filter/search, export |
| **Functional Tests** | End-to-end business workflows (e.g., create → approve → complete lifecycle) |

---

## Module L: Inventory & Stock Management

| | |
|---|---|
| **Module Code** | `L` |
| **App Type** | Both |
| **Description** | Item masters, UOM, vendors, PR→PO→GRN workflow, stock ledger, issue tracking, reorder automation. |
| **Total Sub-Modules** | 11 |
| **Total Features (Tasks)** | 24 |
| **Total Sub-Tasks** | 50 |

### Sub-Module Status

| Sub-Mod Code | Sub-Module Name | App Type | Status |
|---|---|---|---|
| `L1` | Item Master & Categorization | Both | ⬜ Pending |
| `L10` | Asset vs Consumable Handling | Both | ⬜ Pending |
| `L11` | Inventory Reports & Analytics | Both | ⬜ Pending |
| `L2` | Units of Measurement (UOM) | Both | ⬜ Pending |
| `L3` | Vendor & Supplier Linkage | Both | ⬜ Pending |
| `L4` | Purchase Requisition (PR) | Both | ⬜ Pending |
| `L5` | Purchase Order (PO) | Both | ⬜ Pending |
| `L6` | Goods Receipt Note (GRN) | Both | ⬜ Pending |
| `L7` | Stock Ledger & Movement | Both | ⬜ Pending |
| `L8` | Stock Issue / Consumption | Both | ⬜ Pending |
| `L9` | Reorder Automation | Both | ⬜ Pending |

### L1: Item Master & Categorization

**Status:** ⬜ Pending

#### `F.L1.1` — Item Categories

##### `T.L1.1.1` — Create Category

**Sub-Tasks:**

- `ST.L1.1.1.1` Define main category and code
- `ST.L1.1.1.2` Set parent category
- `ST.L1.1.1.3` Assign default UOM and tax rules

##### `T.L1.1.2` — Manage Category Tree

**Sub-Tasks:**

- `ST.L1.1.2.1` Reorder hierarchy
- `ST.L1.1.2.2` Deactivate category with audit log

#### `F.L1.2` — Item Master

##### `T.L1.2.1` — Create Item

**Sub-Tasks:**

- `ST.L1.2.1.1` Enter item name & SKU
- `ST.L1.2.1.2` Assign category & UOM
- `ST.L1.2.1.3` Define min/max stock levels

##### `T.L1.2.2` — Item Attributes

**Sub-Tasks:**

- `ST.L1.2.2.1` Set brand/model
- `ST.L1.2.2.2` Enable batch/expiry tracking

**Suggested DB Tables for `L1` — Item Master & Categorization:**

- `item_categories`
- `items`
- `item_units`
- `stock_ledger`

**Key API Endpoints for `L1`:**

```
GET    /api/v1/item-categories           # List / index
POST   /api/v1/item-categories           # Create
GET    /api/v1/item-categories/{id}    # Show
PUT    /api/v1/item-categories/{id}    # Update
DELETE /api/v1/item-categories/{id}    # Delete
GET    /api/v1/item-master           # List / index
POST   /api/v1/item-master           # Create
GET    /api/v1/item-master/{id}    # Show
PUT    /api/v1/item-master/{id}    # Update
DELETE /api/v1/item-master/{id}    # Delete
```

### L10: Asset vs Consumable Handling

**Status:** ⬜ Pending

#### `F.L10.1` — Asset Management

##### `T.L10.1.1` — Register Asset

**Sub-Tasks:**

- `ST.L10.1.1.1` Assign asset tag
- `ST.L10.1.1.2` Record warranty info

#### `F.L10.2` — Asset Tracking

##### `T.L10.2.1` — Movement Register

**Sub-Tasks:**

- `ST.L10.2.1.1` Record asset movement
- `ST.L10.2.1.2` Generate transfer slip

**Suggested DB Tables for `L10` — Asset vs Consumable Handling:**

- `fixed_assets`
- `depreciation_schedules`

**Key API Endpoints for `L10`:**

```
GET    /api/v1/asset-management           # List / index
POST   /api/v1/asset-management           # Create
GET    /api/v1/asset-management/{id}    # Show
PUT    /api/v1/asset-management/{id}    # Update
DELETE /api/v1/asset-management/{id}    # Delete
GET    /api/v1/asset-tracking           # List / index
POST   /api/v1/asset-tracking           # Create
GET    /api/v1/asset-tracking/{id}    # Show
PUT    /api/v1/asset-tracking/{id}    # Update
DELETE /api/v1/asset-tracking/{id}    # Delete
```

### L11: Inventory Reports & Analytics

**Status:** ⬜ Pending

#### `F.L11.1` — Reports

##### `T.L11.1.1` — Stock Reports

**Sub-Tasks:**

- `ST.L11.1.1.1` View item-wise stock
- `ST.L11.1.1.2` Export stock data

#### `F.L11.2` — Analytics

##### `T.L11.2.1` — Consumption Analytics

**Sub-Tasks:**

- `ST.L11.2.1.1` Identify fast-moving items
- `ST.L11.2.1.2` Predict reorder needs

**Suggested DB Tables for `L11` — Inventory Reports & Analytics:**

- `item_categories`
- `items`
- `item_units`
- `stock_ledger`

**Key API Endpoints for `L11`:**

```
GET    /api/v1/reports           # List / index
POST   /api/v1/reports           # Create
GET    /api/v1/reports/{id}    # Show
PUT    /api/v1/reports/{id}    # Update
DELETE /api/v1/reports/{id}    # Delete
GET    /api/v1/analytics           # List / index
POST   /api/v1/analytics           # Create
GET    /api/v1/analytics/{id}    # Show
PUT    /api/v1/analytics/{id}    # Update
DELETE /api/v1/analytics/{id}    # Delete
```

### L2: Units of Measurement (UOM)

**Status:** ⬜ Pending

#### `F.L2.1` — UOM Master

##### `T.L2.1.1` — Create UOM

**Sub-Tasks:**

- `ST.L2.1.1.1` Define UOM name
- `ST.L2.1.1.2` Set decimal precision

#### `F.L2.2` — Conversion Rules

##### `T.L2.2.1` — Define Conversion

**Sub-Tasks:**

- `ST.L2.2.1.1` Create conversion factors (BOX → PCS)
- `ST.L2.2.1.2` Set effective dates

**Suggested DB Tables for `L2` — Units of Measurement (UOM):**

- `units_of_measurement_(uom)_master`
- `units_of_measurement_(uom)_transactions`
- `units_of_measurement_(uom)_logs`

**Key API Endpoints for `L2`:**

```
GET    /api/v1/uom-master           # List / index
POST   /api/v1/uom-master           # Create
GET    /api/v1/uom-master/{id}    # Show
PUT    /api/v1/uom-master/{id}    # Update
DELETE /api/v1/uom-master/{id}    # Delete
GET    /api/v1/conversion-rules           # List / index
POST   /api/v1/conversion-rules           # Create
GET    /api/v1/conversion-rules/{id}    # Show
PUT    /api/v1/conversion-rules/{id}    # Update
DELETE /api/v1/conversion-rules/{id}    # Delete
```

### L3: Vendor & Supplier Linkage

**Status:** ⬜ Pending

#### `F.L3.1` — Vendor Assignment

##### `T.L3.1.1` — Assign Vendor to Item

**Sub-Tasks:**

- `ST.L3.1.1.1` Select preferred vendor
- `ST.L3.1.1.2` Store last purchase rate

#### `F.L3.2` — Rate Contracts

##### `T.L3.2.1` — Define Rate Contract

**Sub-Tasks:**

- `ST.L3.2.1.1` Set validity dates
- `ST.L3.2.1.2` Assign item-wise fixed rates

**Suggested DB Tables for `L3` — Vendor & Supplier Linkage:**

- `vendors`
- `vendor_bills`
- `ap_payments`

**Key API Endpoints for `L3`:**

```
GET    /api/v1/vendor-assignment           # List / index
POST   /api/v1/vendor-assignment           # Create
GET    /api/v1/vendor-assignment/{id}    # Show
PUT    /api/v1/vendor-assignment/{id}    # Update
DELETE /api/v1/vendor-assignment/{id}    # Delete
GET    /api/v1/rate-contracts           # List / index
POST   /api/v1/rate-contracts           # Create
GET    /api/v1/rate-contracts/{id}    # Show
PUT    /api/v1/rate-contracts/{id}    # Update
DELETE /api/v1/rate-contracts/{id}    # Delete
```

### L4: Purchase Requisition (PR)

**Status:** ⬜ Pending

#### `F.L4.1` — PR Creation

##### `T.L4.1.1` — Create PR

**Sub-Tasks:**

- `ST.L4.1.1.1` Select items and quantities
- `ST.L4.1.1.2` Enter required date

##### `T.L4.1.2` — Upload PR in Bulk

**Sub-Tasks:**

- `ST.L4.1.2.1` Upload CSV
- `ST.L4.1.2.2` Validate PR entries

**Suggested DB Tables for `L4` — Purchase Requisition (PR):**

- `purchase_requisitions`
- `pr_items`

**Key API Endpoints for `L4`:**

```
GET    /api/v1/pr-creation           # List / index
POST   /api/v1/pr-creation           # Create
GET    /api/v1/pr-creation/{id}    # Show
PUT    /api/v1/pr-creation/{id}    # Update
DELETE /api/v1/pr-creation/{id}    # Delete
```

### L5: Purchase Order (PO)

**Status:** ⬜ Pending

#### `F.L5.1` — PO Creation

##### `T.L5.1.1` — Convert PR to PO

**Sub-Tasks:**

- `ST.L5.1.1.1` Select approved PR lines
- `ST.L5.1.1.2` Assign supplier & pricing

#### `F.L5.2` — PO Lifecycle

##### `T.L5.2.1` — Modify PO

**Sub-Tasks:**

- `ST.L5.2.1.1` Edit quantities
- `ST.L5.2.1.2` Record revision history

**Suggested DB Tables for `L5` — Purchase Order (PO):**

- `purchase_orders`
- `po_items`

**Key API Endpoints for `L5`:**

```
GET    /api/v1/po-creation           # List / index
POST   /api/v1/po-creation           # Create
GET    /api/v1/po-creation/{id}    # Show
PUT    /api/v1/po-creation/{id}    # Update
DELETE /api/v1/po-creation/{id}    # Delete
GET    /api/v1/po-lifecycle           # List / index
POST   /api/v1/po-lifecycle           # Create
GET    /api/v1/po-lifecycle/{id}    # Show
PUT    /api/v1/po-lifecycle/{id}    # Update
DELETE /api/v1/po-lifecycle/{id}    # Delete
```

### L6: Goods Receipt Note (GRN)

**Status:** ⬜ Pending

#### `F.L6.1` — GRN Processing

##### `T.L6.1.1` — Create GRN

**Sub-Tasks:**

- `ST.L6.1.1.1` Verify items received
- `ST.L6.1.1.2` Record batch/expiry

#### `F.L6.2` — Quality Check

##### `T.L6.2.1` — QC Process

**Sub-Tasks:**

- `ST.L6.2.1.1` Record pass/fail
- `ST.L6.2.1.2` Add QC notes

**Suggested DB Tables for `L6` — Goods Receipt Note (GRN):**

- `goods_receipts`
- `grn_items`
- `quality_checks`

**Key API Endpoints for `L6`:**

```
GET    /api/v1/grn-processing           # List / index
POST   /api/v1/grn-processing           # Create
GET    /api/v1/grn-processing/{id}    # Show
PUT    /api/v1/grn-processing/{id}    # Update
DELETE /api/v1/grn-processing/{id}    # Delete
GET    /api/v1/quality-check           # List / index
POST   /api/v1/quality-check           # Create
GET    /api/v1/quality-check/{id}    # Show
PUT    /api/v1/quality-check/{id}    # Update
DELETE /api/v1/quality-check/{id}    # Delete
```

### L7: Stock Ledger & Movement

**Status:** ⬜ Pending

#### `F.L7.1` — Stock Inward

##### `T.L7.1.1` — Post Inward

**Sub-Tasks:**

- `ST.L7.1.1.1` Update stock ledger
- `ST.L7.1.1.2` Record supplier details

#### `F.L7.2` — Stock Outward

##### `T.L7.2.1` — Issue to Department

**Sub-Tasks:**

- `ST.L7.2.1.1` Generate issue slip
- `ST.L7.2.1.2` Record acknowledgment

**Suggested DB Tables for `L7` — Stock Ledger & Movement:**

- `stock_ledger_movement_master`
- `stock_ledger_movement_transactions`
- `stock_ledger_movement_logs`

**Key API Endpoints for `L7`:**

```
GET    /api/v1/stock-inward           # List / index
POST   /api/v1/stock-inward           # Create
GET    /api/v1/stock-inward/{id}    # Show
PUT    /api/v1/stock-inward/{id}    # Update
DELETE /api/v1/stock-inward/{id}    # Delete
GET    /api/v1/stock-outward           # List / index
POST   /api/v1/stock-outward           # Create
GET    /api/v1/stock-outward/{id}    # Show
PUT    /api/v1/stock-outward/{id}    # Update
DELETE /api/v1/stock-outward/{id}    # Delete
```

### L8: Stock Issue / Consumption

**Status:** ⬜ Pending

#### `F.L8.1` — Issue Request

##### `T.L8.1.1` — Create Issue Request

**Sub-Tasks:**

- `ST.L8.1.1.1` Select items
- `ST.L8.1.1.2` Set required quantity

#### `F.L8.2` — Consumption Tracking

##### `T.L8.2.1` — Record Usage

**Sub-Tasks:**

- `ST.L8.2.1.1` Update consumed quantity
- `ST.L8.2.1.2` Track per department

**Suggested DB Tables for `L8` — Stock Issue / Consumption:**

- `stock_issue___consumption_master`
- `stock_issue___consumption_transactions`
- `stock_issue___consumption_logs`

**Key API Endpoints for `L8`:**

```
GET    /api/v1/issue-request           # List / index
POST   /api/v1/issue-request           # Create
GET    /api/v1/issue-request/{id}    # Show
PUT    /api/v1/issue-request/{id}    # Update
DELETE /api/v1/issue-request/{id}    # Delete
GET    /api/v1/consumption-tracking           # List / index
POST   /api/v1/consumption-tracking           # Create
GET    /api/v1/consumption-tracking/{id}    # Show
PUT    /api/v1/consumption-tracking/{id}    # Update
DELETE /api/v1/consumption-tracking/{id}    # Delete
```

### L9: Reorder Automation

**Status:** ⬜ Pending

#### `F.L9.1` — Alerts

##### `T.L9.1.1` — Minimum Stock Alert

**Sub-Tasks:**

- `ST.L9.1.1.1` Trigger alert when below threshold
- `ST.L9.1.1.2` Notify store manager

#### `F.L9.2` — Auto-PR

##### `T.L9.2.1` — Generate Auto PR

**Sub-Tasks:**

- `ST.L9.2.1.1` Auto-calc reorder qty
- `ST.L9.2.1.2` Assign preferred vendor

**Suggested DB Tables for `L9` — Reorder Automation:**

- `reorder_automation_master`
- `reorder_automation_transactions`
- `reorder_automation_logs`

**Key API Endpoints for `L9`:**

```
GET    /api/v1/alerts           # List / index
POST   /api/v1/alerts           # Create
GET    /api/v1/alerts/{id}    # Show
PUT    /api/v1/alerts/{id}    # Update
DELETE /api/v1/alerts/{id}    # Delete
GET    /api/v1/auto-pr           # List / index
POST   /api/v1/auto-pr           # Create
GET    /api/v1/auto-pr/{id}    # Show
PUT    /api/v1/auto-pr/{id}    # Update
DELETE /api/v1/auto-pr/{id}    # Delete
```

### Screen Design Requirements — Module L


### Report Requirements — Module L

- **Reports**: Tabular report with date range filter, export to PDF/Excel/CSV
- **Analytics**: Tabular report with date range filter, export to PDF/Excel/CSV

### Test Case Requirements — Module L

| Test Type | Scope |
|---|---|
| **Unit Tests** | All service classes and model methods in Module L |
| **Feature Tests** | All API endpoints — happy path, validation errors, auth failures |
| **Browser Tests** | Form submissions, list pagination, filter/search, export |
| **Functional Tests** | End-to-end business workflows (e.g., create → approve → complete lifecycle) |

---

## Module M: Library Management

| | |
|---|---|
| **Module Code** | `M` |
| **App Type** | Both |
| **Description** | Book catalog, member management, issue/return, reservations, fines, stock audit, analytics. |
| **Total Sub-Modules** | 7 |
| **Total Features (Tasks)** | 18 |
| **Total Sub-Tasks** | 37 |

### Sub-Module Status

| Sub-Mod Code | Sub-Module Name | App Type | Status |
|---|---|---|---|
| `M1` | Book & Resource Master | Both | ✅ Completed 100% |
| `M2` | Library Member Management | Both | ✅ Completed 100% |
| `M3` | Book Issue & Return | Both | ✅ Completed 100% |
| `M4` | Reservations & Hold Requests | Both | ✅ Completed 100% |
| `M5` | Inventory & Stock Audit | Both | ✅ Completed 100% |
| `M6` | Fines, Penalties & Payments | Both | ✅ Completed 100% |
| `M7` | Library Reports & Analytics | Both | ✅ Completed 100% |

### M1: Book & Resource Master

**Status:** ✅ Completed 100%

#### `F.M1.1` — Book Catalog

##### `T.M1.1.1` — Add New Book

**Sub-Tasks:**

- `ST.M1.1.1.1` Enter title, author, edition
- `ST.M1.1.1.2` Assign ISBN/Accession number
- `ST.M1.1.1.3` Select category & genre

##### `T.M1.1.2` — Manage Book Copies

**Sub-Tasks:**

- `ST.M1.1.2.1` Add multiple copies
- `ST.M1.1.2.2` Assign barcodes

#### `F.M1.2` — Digital Resources

##### `T.M1.2.1` — Add Digital Resource

**Sub-Tasks:**

- `ST.M1.2.1.1` Upload e-book/PDF
- `ST.M1.2.1.2` Enter metadata & tags

##### `T.M1.2.2` — Manage Licenses

**Sub-Tasks:**

- `ST.M1.2.2.1` Set access restrictions
- `ST.M1.2.2.2` Define license validity

**Suggested DB Tables for `M1` — Book & Resource Master:**

- `rooms`
- `room_constraints`
- `lab_resources`

**Key API Endpoints for `M1`:**

```
GET    /api/v1/book-catalog           # List / index
POST   /api/v1/book-catalog           # Create
GET    /api/v1/book-catalog/{id}    # Show
PUT    /api/v1/book-catalog/{id}    # Update
DELETE /api/v1/book-catalog/{id}    # Delete
GET    /api/v1/digital-resources           # List / index
POST   /api/v1/digital-resources           # Create
GET    /api/v1/digital-resources/{id}    # Show
PUT    /api/v1/digital-resources/{id}    # Update
DELETE /api/v1/digital-resources/{id}    # Delete
```

### M2: Library Member Management

**Status:** ✅ Completed 100%

#### `F.M2.1` — Member Profiles

##### `T.M2.1.1` — Register Member

**Sub-Tasks:**

- `ST.M2.1.1.1` Link student/staff profile
- `ST.M2.1.1.2` Assign membership type

##### `T.M2.1.2` — Manage Membership

**Sub-Tasks:**

- `ST.M2.1.2.1` Renew membership
- `ST.M2.1.2.2` Deactivate member

**Suggested DB Tables for `M2` — Library Member Management:**

- `books`
- `book_copies`
- `library_members`
- `book_issues`

**Key API Endpoints for `M2`:**

```
GET    /api/v1/member-profiles           # List / index
POST   /api/v1/member-profiles           # Create
GET    /api/v1/member-profiles/{id}    # Show
PUT    /api/v1/member-profiles/{id}    # Update
DELETE /api/v1/member-profiles/{id}    # Delete
```

### M3: Book Issue & Return

**Status:** ✅ Completed 100%

#### `F.M3.1` — Issue Process

##### `T.M3.1.1` — Issue Book

**Sub-Tasks:**

- `ST.M3.1.1.1` Scan book barcode
- `ST.M3.1.1.2` Validate member limits

##### `T.M3.1.2` — Due Date Calculation

**Sub-Tasks:**

- `ST.M3.1.2.1` Auto-calculate due date
- `ST.M3.1.2.2` Apply special rules for staff

#### `F.M3.2` — Return Process

##### `T.M3.2.1` — Return Book

**Sub-Tasks:**

- `ST.M3.2.1.1` Scan and update status
- `ST.M3.2.1.2` Record condition on return

##### `T.M3.2.2` — Late Return Handling

**Sub-Tasks:**

- `ST.M3.2.2.1` Calculate fine
- `ST.M3.2.2.2` Add fine to member account

**Suggested DB Tables for `M3` — Book Issue & Return:**

- `books`
- `book_copies`
- `library_members`
- `book_issues`

**Key API Endpoints for `M3`:**

```
GET    /api/v1/issue-process           # List / index
POST   /api/v1/issue-process           # Create
GET    /api/v1/issue-process/{id}    # Show
PUT    /api/v1/issue-process/{id}    # Update
DELETE /api/v1/issue-process/{id}    # Delete
GET    /api/v1/return-process           # List / index
POST   /api/v1/return-process           # Create
GET    /api/v1/return-process/{id}    # Show
PUT    /api/v1/return-process/{id}    # Update
DELETE /api/v1/return-process/{id}    # Delete
```

### M4: Reservations & Hold Requests

**Status:** ✅ Completed 100%

#### `F.M4.1` — Reservation

##### `T.M4.1.1` — Place Reservation

**Sub-Tasks:**

- `ST.M4.1.1.1` Select book to reserve
- `ST.M4.1.1.2` Check availability

##### `T.M4.1.2` — Notify Availability

**Sub-Tasks:**

- `ST.M4.1.2.1` Send SMS/email when book is available
- `ST.M4.1.2.2` Auto-cancel if not collected

**Suggested DB Tables for `M4` — Reservations & Hold Requests:**

- `reservations_hold_requests_master`
- `reservations_hold_requests_transactions`
- `reservations_hold_requests_logs`

**Key API Endpoints for `M4`:**

```
GET    /api/v1/reservation           # List / index
POST   /api/v1/reservation           # Create
GET    /api/v1/reservation/{id}    # Show
PUT    /api/v1/reservation/{id}    # Update
DELETE /api/v1/reservation/{id}    # Delete
```

### M5: Inventory & Stock Audit

**Status:** ✅ Completed 100%

#### `F.M5.1` — Physical Stock Verification

##### `T.M5.1.1` — Perform Stock Audit

**Sub-Tasks:**

- `ST.M5.1.1.1` Scan all book barcodes
- `ST.M5.1.1.2` Identify missing books

#### `F.M5.2` — Shelf Management

##### `T.M5.2.1` — Assign Shelf Location

**Sub-Tasks:**

- `ST.M5.2.1.1` Set aisle/shelf number
- `ST.M5.2.1.2` Update shelf mapping

**Suggested DB Tables for `M5` — Inventory & Stock Audit:**

- `audit_logs`
- `system_events`

**Key API Endpoints for `M5`:**

```
GET    /api/v1/physical-stock-verification           # List / index
POST   /api/v1/physical-stock-verification           # Create
GET    /api/v1/physical-stock-verification/{id}    # Show
PUT    /api/v1/physical-stock-verification/{id}    # Update
DELETE /api/v1/physical-stock-verification/{id}    # Delete
GET    /api/v1/shelf-management           # List / index
POST   /api/v1/shelf-management           # Create
GET    /api/v1/shelf-management/{id}    # Show
PUT    /api/v1/shelf-management/{id}    # Update
DELETE /api/v1/shelf-management/{id}    # Delete
```

### M6: Fines, Penalties & Payments

**Status:** ✅ Completed 100%

#### `F.M6.1` — Fine Calculation

##### `T.M6.1.1` — Daily Fine Rules

**Sub-Tasks:**

- `ST.M6.1.1.1` Define fine per day
- `ST.M6.1.1.2` Add grace period

#### `F.M6.2` — Fine Payment

##### `T.M6.2.1` — Record Fine Payment

**Sub-Tasks:**

- `ST.M6.2.1.1` Accept payment
- `ST.M6.2.1.2` Generate fine receipt

**Suggested DB Tables for `M6` — Fines, Penalties & Payments:**

- `fines,_penalties_payments_master`
- `fines,_penalties_payments_transactions`
- `fines,_penalties_payments_logs`

**Key API Endpoints for `M6`:**

```
GET    /api/v1/fine-calculation           # List / index
POST   /api/v1/fine-calculation           # Create
GET    /api/v1/fine-calculation/{id}    # Show
PUT    /api/v1/fine-calculation/{id}    # Update
DELETE /api/v1/fine-calculation/{id}    # Delete
GET    /api/v1/fine-payment           # List / index
POST   /api/v1/fine-payment           # Create
GET    /api/v1/fine-payment/{id}    # Show
PUT    /api/v1/fine-payment/{id}    # Update
DELETE /api/v1/fine-payment/{id}    # Delete
```

### M7: Library Reports & Analytics

**Status:** ✅ Completed 100%

#### `F.M7.1` — Reports

##### `T.M7.1.1` — Generate Reports

**Sub-Tasks:**

- `ST.M7.1.1.1` Most issued books report
- `ST.M7.1.1.2` Overdue books report

#### `F.M7.2` — Analytics

##### `T.M7.2.1` — Usage Insights

**Sub-Tasks:**

- `ST.M7.2.1.1` Identify reading trends
- `ST.M7.2.1.2` Calculate resource utilization

**Suggested DB Tables for `M7` — Library Reports & Analytics:**

- `books`
- `book_copies`
- `library_members`
- `book_issues`

**Key API Endpoints for `M7`:**

```
GET    /api/v1/reports           # List / index
POST   /api/v1/reports           # Create
GET    /api/v1/reports/{id}    # Show
PUT    /api/v1/reports/{id}    # Update
DELETE /api/v1/reports/{id}    # Delete
GET    /api/v1/analytics           # List / index
POST   /api/v1/analytics           # Create
GET    /api/v1/analytics/{id}    # Show
PUT    /api/v1/analytics/{id}    # Update
DELETE /api/v1/analytics/{id}    # Delete
```

### Screen Design Requirements — Module M


### Report Requirements — Module M

- **Book Catalog**: Tabular report with date range filter, export to PDF/Excel/CSV
- **Reports**: Tabular report with date range filter, export to PDF/Excel/CSV
- **Analytics**: Tabular report with date range filter, export to PDF/Excel/CSV

### Test Case Requirements — Module M

| Test Type | Scope |
|---|---|
| **Unit Tests** | All service classes and model methods in Module M |
| **Feature Tests** | All API endpoints — happy path, validation errors, auth failures |
| **Browser Tests** | Form submissions, list pagination, filter/search, export |
| **Functional Tests** | End-to-end business workflows (e.g., create → approve → complete lifecycle) |

---

## Module N: Transport Management

| | |
|---|---|
| **Module Code** | `N` |
| **App Type** | Both |
| **Description** | Routes, vehicles, drivers, student allocation, GPS tracking, transport attendance, fee integration. |
| **Total Sub-Modules** | 8 |
| **Total Features (Tasks)** | 18 |
| **Total Sub-Tasks** | 37 |

### Sub-Module Status

| Sub-Mod Code | Sub-Module Name | App Type | Status |
|---|---|---|---|
| `N1` | Route & Stop Management | Both | ✅ Completed 100% |
| `N2` | Vehicle & Driver Management | Both | ✅ Completed 100% |
| `N3` | Student Transport Allocation | Both | ✅ Completed 100% |
| `N4` | Vehicle Tracking & GPS Monitoring | Both | ✅ Completed 100% |
| `N5` | Transport Attendance | Both | ✅ Completed 100% |
| `N6` | Transport Fee Integration | Both | ✅ Completed 100% |
| `N7` | Safety & Compliance | Both | ✅ Completed 100% |
| `N8` | Reports & Analytics | Both | ✅ Completed 100% |

### N1: Route & Stop Management

**Status:** ✅ Completed 100%

#### `F.N1.1` — Route Setup

##### `T.N1.1.1` — Create Route

**Sub-Tasks:**

- `ST.N1.1.1.1` Define route name/number
- `ST.N1.1.1.2` Enter start and end points
- `ST.N1.1.1.3` Assign driver and vehicle

##### `T.N1.1.2` — Manage Stops

**Sub-Tasks:**

- `ST.N1.1.2.1` Add bus stops with geo-coordinates
- `ST.N1.1.2.2` Set pickup/drop sequence

**Suggested DB Tables for `N1` — Route & Stop Management:**

- `transport_routes`
- `route_stops`
- `vehicles`
- `drivers`
- `student_transports`

**Key API Endpoints for `N1`:**

```
GET    /api/v1/route-setup           # List / index
POST   /api/v1/route-setup           # Create
GET    /api/v1/route-setup/{id}    # Show
PUT    /api/v1/route-setup/{id}    # Update
DELETE /api/v1/route-setup/{id}    # Delete
```

### N2: Vehicle & Driver Management

**Status:** ✅ Completed 100%

#### `F.N2.1` — Vehicle Master

##### `T.N2.1.1` — Add Vehicle

**Sub-Tasks:**

- `ST.N2.1.1.1` Enter vehicle number & type
- `ST.N2.1.1.2` Upload RC/insurance documents

##### `T.N2.1.2` — Vehicle Maintenance

**Sub-Tasks:**

- `ST.N2.1.2.1` Record service schedule
- `ST.N2.1.2.2` Track maintenance history

#### `F.N2.2` — Driver Profiles

##### `T.N2.2.1` — Add Driver

**Sub-Tasks:**

- `ST.N2.2.1.1` Enter driver license details
- `ST.N2.2.1.2` Upload ID proof

##### `T.N2.2.2` — Driver Assignment

**Sub-Tasks:**

- `ST.N2.2.2.1` Assign driver to vehicle
- `ST.N2.2.2.2` Track duty schedule

**Suggested DB Tables for `N2` — Vehicle & Driver Management:**

- `vehicle_driver_management_master`
- `vehicle_driver_management_transactions`
- `vehicle_driver_management_logs`

**Key API Endpoints for `N2`:**

```
GET    /api/v1/vehicle-master           # List / index
POST   /api/v1/vehicle-master           # Create
GET    /api/v1/vehicle-master/{id}    # Show
PUT    /api/v1/vehicle-master/{id}    # Update
DELETE /api/v1/vehicle-master/{id}    # Delete
GET    /api/v1/driver-profiles           # List / index
POST   /api/v1/driver-profiles           # Create
GET    /api/v1/driver-profiles/{id}    # Show
PUT    /api/v1/driver-profiles/{id}    # Update
DELETE /api/v1/driver-profiles/{id}    # Delete
```

### N3: Student Transport Allocation

**Status:** ✅ Completed 100%

#### `F.N3.1` — Stop Allocation

##### `T.N3.1.1` — Assign Stop

**Sub-Tasks:**

- `ST.N3.1.1.1` Select pickup/drop stop
- `ST.N3.1.1.2` Define pickup/drop timing

##### `T.N3.1.2` — Change Stop

**Sub-Tasks:**

- `ST.N3.1.2.1` Request stop change
- `ST.N3.1.2.2` Approve/Reject change

**Suggested DB Tables for `N3` — Student Transport Allocation:**

- `transport_routes`
- `route_stops`
- `vehicles`
- `drivers`
- `student_transports`

**Key API Endpoints for `N3`:**

```
GET    /api/v1/stop-allocation           # List / index
POST   /api/v1/stop-allocation           # Create
GET    /api/v1/stop-allocation/{id}    # Show
PUT    /api/v1/stop-allocation/{id}    # Update
DELETE /api/v1/stop-allocation/{id}    # Delete
```

### N4: Vehicle Tracking & GPS Monitoring

**Status:** ✅ Completed 100%

#### `F.N4.1` — Live Tracking

##### `T.N4.1.1` — Track Vehicle

**Sub-Tasks:**

- `ST.N4.1.1.1` View real-time GPS location
- `ST.N4.1.1.2` Show route deviation alerts

#### `F.N4.2` — Notifications

##### `T.N4.2.1` — Pickup Alerts

**Sub-Tasks:**

- `ST.N4.2.1.1` Notify parents when bus nears stop
- `ST.N4.2.1.2` Send delay alerts

**Suggested DB Tables for `N4` — Vehicle Tracking & GPS Monitoring:**

- `audit_logs`
- `system_events`

**Key API Endpoints for `N4`:**

```
GET    /api/v1/live-tracking           # List / index
POST   /api/v1/live-tracking           # Create
GET    /api/v1/live-tracking/{id}    # Show
PUT    /api/v1/live-tracking/{id}    # Update
DELETE /api/v1/live-tracking/{id}    # Delete
GET    /api/v1/notifications           # List / index
POST   /api/v1/notifications           # Create
GET    /api/v1/notifications/{id}    # Show
PUT    /api/v1/notifications/{id}    # Update
DELETE /api/v1/notifications/{id}    # Delete
```

### N5: Transport Attendance

**Status:** ✅ Completed 100%

#### `F.N5.1` — Student Transport Attendance

##### `T.N5.1.1` — Mark Bus Attendance

**Sub-Tasks:**

- `ST.N5.1.1.1` Record boarding status
- `ST.N5.1.1.2` Auto-sync with school attendance

#### `F.N5.2` — Driver Attendance

##### `T.N5.2.1` — Record Driver Attendance

**Sub-Tasks:**

- `ST.N5.2.1.1` Capture check-in/out
- `ST.N5.2.1.2` Sync with HR attendance module

**Suggested DB Tables for `N5` — Transport Attendance:**

- `transport_routes`
- `route_stops`
- `vehicles`
- `drivers`
- `student_transports`

**Key API Endpoints for `N5`:**

```
GET    /api/v1/student-transport-attendance           # List / index
POST   /api/v1/student-transport-attendance           # Create
GET    /api/v1/student-transport-attendance/{id}    # Show
PUT    /api/v1/student-transport-attendance/{id}    # Update
DELETE /api/v1/student-transport-attendance/{id}    # Delete
GET    /api/v1/driver-attendance           # List / index
POST   /api/v1/driver-attendance           # Create
GET    /api/v1/driver-attendance/{id}    # Show
PUT    /api/v1/driver-attendance/{id}    # Update
DELETE /api/v1/driver-attendance/{id}    # Delete
```

### N6: Transport Fee Integration

**Status:** ✅ Completed 100%

#### `F.N6.1` — Fee Mapping

##### `T.N6.1.1` — Map Route to Fee

**Sub-Tasks:**

- `ST.N6.1.1.1` Assign route-wise fee
- `ST.N6.1.1.2` Auto-calculate monthly charges

#### `F.N6.2` — Fee Adjustment

##### `T.N6.2.1` — Apply Adjustments

**Sub-Tasks:**

- `ST.N6.2.1.1` Handle mid-session route change
- `ST.N6.2.1.2` Apply prorated fees

**Suggested DB Tables for `N6` — Transport Fee Integration:**

- `transport_routes`
- `route_stops`
- `vehicles`
- `drivers`
- `student_transports`

**Key API Endpoints for `N6`:**

```
GET    /api/v1/fee-mapping           # List / index
POST   /api/v1/fee-mapping           # Create
GET    /api/v1/fee-mapping/{id}    # Show
PUT    /api/v1/fee-mapping/{id}    # Update
DELETE /api/v1/fee-mapping/{id}    # Delete
GET    /api/v1/fee-adjustment           # List / index
POST   /api/v1/fee-adjustment           # Create
GET    /api/v1/fee-adjustment/{id}    # Show
PUT    /api/v1/fee-adjustment/{id}    # Update
DELETE /api/v1/fee-adjustment/{id}    # Delete
```

### N7: Safety & Compliance

**Status:** ✅ Completed 100%

#### `F.N7.1` — Safety Protocols

##### `T.N7.1.1` — Record Safety Checklist

**Sub-Tasks:**

- `ST.N7.1.1.1` Daily vehicle inspection checklist
- `ST.N7.1.1.2` Record driver alcohol test

#### `F.N7.2` — Compliance Documents

##### `T.N7.2.1` — Maintain Documents

**Sub-Tasks:**

- `ST.N7.2.1.1` Upload vehicle fitness certificate
- `ST.N7.2.1.2` Track expiry reminders

**Suggested DB Tables for `N7` — Safety & Compliance:**

- `pf_esi_configs`
- `statutory_reports`

**Key API Endpoints for `N7`:**

```
GET    /api/v1/safety-protocols           # List / index
POST   /api/v1/safety-protocols           # Create
GET    /api/v1/safety-protocols/{id}    # Show
PUT    /api/v1/safety-protocols/{id}    # Update
DELETE /api/v1/safety-protocols/{id}    # Delete
GET    /api/v1/compliance-documents           # List / index
POST   /api/v1/compliance-documents           # Create
GET    /api/v1/compliance-documents/{id}    # Show
PUT    /api/v1/compliance-documents/{id}    # Update
DELETE /api/v1/compliance-documents/{id}    # Delete
```

### N8: Reports & Analytics

**Status:** ✅ Completed 100%

#### `F.N8.1` — Transport Reports

##### `T.N8.1.1` — Generate Reports

**Sub-Tasks:**

- `ST.N8.1.1.1` Route efficiency report
- `ST.N8.1.1.2` Vehicle usage report

#### `F.N8.2` — AI-Based Optimization

##### `T.N8.2.1` — Optimize Routes

**Sub-Tasks:**

- `ST.N8.2.1.1` Suggest shortest paths
- `ST.N8.2.1.2` Predict high-traffic delays

**Suggested DB Tables for `N8` — Reports & Analytics:**

- `ml_model_configs`
- `prediction_results`
- `analytics_snapshots`

**Key API Endpoints for `N8`:**

```
GET    /api/v1/transport-reports           # List / index
POST   /api/v1/transport-reports           # Create
GET    /api/v1/transport-reports/{id}    # Show
PUT    /api/v1/transport-reports/{id}    # Update
DELETE /api/v1/transport-reports/{id}    # Delete
GET    /api/v1/ai-based-optimization           # List / index
POST   /api/v1/ai-based-optimization           # Create
GET    /api/v1/ai-based-optimization/{id}    # Show
PUT    /api/v1/ai-based-optimization/{id}    # Update
DELETE /api/v1/ai-based-optimization/{id}    # Delete
```

### Screen Design Requirements — Module N


### Report Requirements — Module N

- **Transport Reports**: Tabular report with date range filter, export to PDF/Excel/CSV

### Test Case Requirements — Module N

| Test Type | Scope |
|---|---|
| **Unit Tests** | All service classes and model methods in Module N |
| **Feature Tests** | All API endpoints — happy path, validation errors, auth failures |
| **Browser Tests** | Form submissions, list pagination, filter/search, export |
| **Functional Tests** | End-to-end business workflows (e.g., create → approve → complete lifecycle) |

---

## Module O: Hostel Management

| | |
|---|---|
| **Module Code** | `O` |
| **App Type** | Both |
| **Description** | Hostel/room setup, student allotment, attendance, mess management, hostel fees, discipline, inventory. |
| **Total Sub-Modules** | 8 |
| **Total Features (Tasks)** | 18 |
| **Total Sub-Tasks** | 36 |

### Sub-Module Status

| Sub-Mod Code | Sub-Module Name | App Type | Status |
|---|---|---|---|
| `O1` | Hostel & Room Setup | Both | ⬜ Pending |
| `O2` | Student Allotment & Movement | Both | ⬜ Pending |
| `O3` | Attendance & In-Out Register | Both | ⬜ Pending |
| `O4` | Mess Management | Both | ⬜ Pending |
| `O5` | Hostel Fee Management | Both | ⬜ Pending |
| `O6` | Discipline & Incident Management | Both | ⬜ Pending |
| `O7` | Hostel Inventory Management | Both | ⬜ Pending |
| `O8` | Reports & Analytics | Both | ✅ Completed 100% |

### O1: Hostel & Room Setup

**Status:** ⬜ Pending

#### `F.O1.1` — Hostel Configuration

##### `T.O1.1.1` — Create Hostel

**Sub-Tasks:**

- `ST.O1.1.1.1` Define hostel name & address
- `ST.O1.1.1.2` Assign warden & contact details

##### `T.O1.1.2` — Hostel Facilities

**Sub-Tasks:**

- `ST.O1.1.2.1` List available facilities
- `ST.O1.1.2.2` Define facility usage rules

#### `F.O1.2` — Room Setup

##### `T.O1.2.1` — Create Rooms

**Sub-Tasks:**

- `ST.O1.2.1.1` Define room number/type
- `ST.O1.2.1.2` Set room capacity

##### `T.O1.2.2` — Room Allocation Rules

**Sub-Tasks:**

- `ST.O1.2.2.1` Set gender-based restrictions
- `ST.O1.2.2.2` Set priority allocation rules

**Suggested DB Tables for `O1` — Hostel & Room Setup:**

- `rooms`
- `room_constraints`
- `lab_resources`

**Key API Endpoints for `O1`:**

```
GET    /api/v1/hostel-configuration           # List / index
POST   /api/v1/hostel-configuration           # Create
GET    /api/v1/hostel-configuration/{id}    # Show
PUT    /api/v1/hostel-configuration/{id}    # Update
DELETE /api/v1/hostel-configuration/{id}    # Delete
GET    /api/v1/room-setup           # List / index
POST   /api/v1/room-setup           # Create
GET    /api/v1/room-setup/{id}    # Show
PUT    /api/v1/room-setup/{id}    # Update
DELETE /api/v1/room-setup/{id}    # Delete
```

### O2: Student Allotment & Movement

**Status:** ⬜ Pending

#### `F.O2.1` — Room Allotment

##### `T.O2.1.1` — Assign Room

**Sub-Tasks:**

- `ST.O2.1.1.1` Select student
- `ST.O2.1.1.2` Assign room & bed number

#### `F.O2.2` — Room Change Requests

##### `T.O2.2.1` — Handle Requests

**Sub-Tasks:**

- `ST.O2.2.1.1` Record room change reason
- `ST.O2.2.1.2` Approve/Reject request

**Suggested DB Tables for `O2` — Student Allotment & Movement:**

- `student_allotment_movement_master`
- `student_allotment_movement_transactions`
- `student_allotment_movement_logs`

**Key API Endpoints for `O2`:**

```
GET    /api/v1/room-allotment           # List / index
POST   /api/v1/room-allotment           # Create
GET    /api/v1/room-allotment/{id}    # Show
PUT    /api/v1/room-allotment/{id}    # Update
DELETE /api/v1/room-allotment/{id}    # Delete
GET    /api/v1/room-change-requests           # List / index
POST   /api/v1/room-change-requests           # Create
GET    /api/v1/room-change-requests/{id}    # Show
PUT    /api/v1/room-change-requests/{id}    # Update
DELETE /api/v1/room-change-requests/{id}    # Delete
```

### O3: Attendance & In-Out Register

**Status:** ⬜ Pending

#### `F.O3.1` — Daily Attendance

##### `T.O3.1.1` — Record Attendance

**Sub-Tasks:**

- `ST.O3.1.1.1` Mark present/absent
- `ST.O3.1.1.2` Capture late entry remarks

#### `F.O3.2` — In-Out Register

##### `T.O3.2.1` — Log Movement

**Sub-Tasks:**

- `ST.O3.2.1.1` Record out-time & reason
- `ST.O3.2.1.2` Record in-time

**Suggested DB Tables for `O3` — Attendance & In-Out Register:**

- `attendance_in_out_register_master`
- `attendance_in_out_register_transactions`
- `attendance_in_out_register_logs`

**Key API Endpoints for `O3`:**

```
GET    /api/v1/daily-attendance           # List / index
POST   /api/v1/daily-attendance           # Create
GET    /api/v1/daily-attendance/{id}    # Show
PUT    /api/v1/daily-attendance/{id}    # Update
DELETE /api/v1/daily-attendance/{id}    # Delete
GET    /api/v1/in-out-register           # List / index
POST   /api/v1/in-out-register           # Create
GET    /api/v1/in-out-register/{id}    # Show
PUT    /api/v1/in-out-register/{id}    # Update
DELETE /api/v1/in-out-register/{id}    # Delete
```

### O4: Mess Management

**Status:** ⬜ Pending

#### `F.O4.1` — Meal Planning

##### `T.O4.1.1` — Define Weekly Menu

**Sub-Tasks:**

- `ST.O4.1.1.1` Set meal plan for week
- `ST.O4.1.1.2` Assign special diet schedules

#### `F.O4.2` — Mess Attendance

##### `T.O4.2.1` — Record Meal Attendance

**Sub-Tasks:**

- `ST.O4.2.1.1` Track meal consumption
- `ST.O4.2.1.2` Record special diet served

**Suggested DB Tables for `O4` — Mess Management:**

- `meal_menus`
- `meal_orders`
- `kitchen_stock`

**Key API Endpoints for `O4`:**

```
GET    /api/v1/meal-planning           # List / index
POST   /api/v1/meal-planning           # Create
GET    /api/v1/meal-planning/{id}    # Show
PUT    /api/v1/meal-planning/{id}    # Update
DELETE /api/v1/meal-planning/{id}    # Delete
GET    /api/v1/mess-attendance           # List / index
POST   /api/v1/mess-attendance           # Create
GET    /api/v1/mess-attendance/{id}    # Show
PUT    /api/v1/mess-attendance/{id}    # Update
DELETE /api/v1/mess-attendance/{id}    # Delete
```

### O5: Hostel Fee Management

**Status:** ⬜ Pending

#### `F.O5.1` — Fee Assignment

##### `T.O5.1.1` — Assign Hostel Fee

**Sub-Tasks:**

- `ST.O5.1.1.1` Select student & room type
- `ST.O5.1.1.2` Apply mess charges

#### `F.O5.2` — Fee Adjustments

##### `T.O5.2.1` — Prorated Fee

**Sub-Tasks:**

- `ST.O5.2.1.1` Calculate partial month fee
- `ST.O5.2.1.2` Apply room change difference

**Suggested DB Tables for `O5` — Hostel Fee Management:**

- `hostels`
- `hostel_rooms`
- `student_room_allotments`
- `hostel_attendance`

**Key API Endpoints for `O5`:**

```
GET    /api/v1/fee-assignment           # List / index
POST   /api/v1/fee-assignment           # Create
GET    /api/v1/fee-assignment/{id}    # Show
PUT    /api/v1/fee-assignment/{id}    # Update
DELETE /api/v1/fee-assignment/{id}    # Delete
GET    /api/v1/fee-adjustments           # List / index
POST   /api/v1/fee-adjustments           # Create
GET    /api/v1/fee-adjustments/{id}    # Show
PUT    /api/v1/fee-adjustments/{id}    # Update
DELETE /api/v1/fee-adjustments/{id}    # Delete
```

### O6: Discipline & Incident Management

**Status:** ⬜ Pending

#### `F.O6.1` — Discipline Tracking

##### `T.O6.1.1` — Record Incident

**Sub-Tasks:**

- `ST.O6.1.1.1` Enter incident description
- `ST.O6.1.1.2` Attach supporting documents

#### `F.O6.2` — Action Workflow

##### `T.O6.2.1` — Issue Warning

**Sub-Tasks:**

- `ST.O6.2.1.1` Send warning letter
- `ST.O6.2.1.2` Notify parents

**Suggested DB Tables for `O6` — Discipline & Incident Management:**

- `discipline_incident_management_master`
- `discipline_incident_management_transactions`
- `discipline_incident_management_logs`

**Key API Endpoints for `O6`:**

```
GET    /api/v1/discipline-tracking           # List / index
POST   /api/v1/discipline-tracking           # Create
GET    /api/v1/discipline-tracking/{id}    # Show
PUT    /api/v1/discipline-tracking/{id}    # Update
DELETE /api/v1/discipline-tracking/{id}    # Delete
GET    /api/v1/action-workflow           # List / index
POST   /api/v1/action-workflow           # Create
GET    /api/v1/action-workflow/{id}    # Show
PUT    /api/v1/action-workflow/{id}    # Update
DELETE /api/v1/action-workflow/{id}    # Delete
```

### O7: Hostel Inventory Management

**Status:** ⬜ Pending

#### `F.O7.1` — Inventory Tracking

##### `T.O7.1.1` — Record Items

**Sub-Tasks:**

- `ST.O7.1.1.1` Add beds/mattresses/tables
- `ST.O7.1.1.2` Assign condition status

#### `F.O7.2` — Damage Reporting

##### `T.O7.2.1` — Record Damages

**Sub-Tasks:**

- `ST.O7.2.1.1` Log damaged item
- `ST.O7.2.1.2` Estimate repair cost

**Suggested DB Tables for `O7` — Hostel Inventory Management:**

- `item_categories`
- `items`
- `item_units`
- `stock_ledger`

**Key API Endpoints for `O7`:**

```
GET    /api/v1/inventory-tracking           # List / index
POST   /api/v1/inventory-tracking           # Create
GET    /api/v1/inventory-tracking/{id}    # Show
PUT    /api/v1/inventory-tracking/{id}    # Update
DELETE /api/v1/inventory-tracking/{id}    # Delete
GET    /api/v1/damage-reporting           # List / index
POST   /api/v1/damage-reporting           # Create
GET    /api/v1/damage-reporting/{id}    # Show
PUT    /api/v1/damage-reporting/{id}    # Update
DELETE /api/v1/damage-reporting/{id}    # Delete
```

### O8: Reports & Analytics

**Status:** ✅ Completed 100%

#### `F.O8.1` — Hostel Reports

##### `T.O8.1.1` — Generate Reports

**Sub-Tasks:**

- `ST.O8.1.1.1` Hostel occupancy report
- `ST.O8.1.1.2` Room utilization report

#### `F.O8.2` — Analytics

##### `T.O8.2.1` — Predict Trends

**Sub-Tasks:**

- `ST.O8.2.1.1` Forecast room demand
- `ST.O8.2.1.2` Identify peak usage months

**Suggested DB Tables for `O8` — Reports & Analytics:**

- `ml_model_configs`
- `prediction_results`
- `analytics_snapshots`

**Key API Endpoints for `O8`:**

```
GET    /api/v1/hostel-reports           # List / index
POST   /api/v1/hostel-reports           # Create
GET    /api/v1/hostel-reports/{id}    # Show
PUT    /api/v1/hostel-reports/{id}    # Update
DELETE /api/v1/hostel-reports/{id}    # Delete
GET    /api/v1/analytics           # List / index
POST   /api/v1/analytics           # Create
GET    /api/v1/analytics/{id}    # Show
PUT    /api/v1/analytics/{id}    # Update
DELETE /api/v1/analytics/{id}    # Delete
```

### Screen Design Requirements — Module O


### Report Requirements — Module O

- **Damage Reporting**: Tabular report with date range filter, export to PDF/Excel/CSV
- **Hostel Reports**: Tabular report with date range filter, export to PDF/Excel/CSV
- **Analytics**: Tabular report with date range filter, export to PDF/Excel/CSV

### Test Case Requirements — Module O

| Test Type | Scope |
|---|---|
| **Unit Tests** | All service classes and model methods in Module O |
| **Feature Tests** | All API endpoints — happy path, validation errors, auth failures |
| **Browser Tests** | Form submissions, list pagination, filter/search, export |
| **Functional Tests** | End-to-end business workflows (e.g., create → approve → complete lifecycle) |

---

## Module P: Human Resources & Staff Mgmt.

| | |
|---|---|
| **Module Code** | `P` |
| **App Type** | Both |
| **Description** | Staff profiles, leave management, payroll, statutory compliance, appraisals, training. |
| **Total Sub-Modules** | 7 |
| **Total Features (Tasks)** | 22 |
| **Total Sub-Tasks** | 46 |

### Sub-Module Status

| Sub-Mod Code | Sub-Module Name | App Type | Status |
|---|---|---|---|
| `P1` | Staff Master & HR Records | Both | ⬜ Pending |
| `P2` | Staff Attendance & Leave | Both | ⬜ Pending |
| `P3` | Payroll Preparation | Both | ⬜ Pending |
| `P4` | Compliance & Statutory Management | Both | ⬜ Pending |
| `P5` | Performance Appraisal | Both | ⬜ Pending |
| `P6` | Staff Training & Development | Both | ⬜ Pending |
| `P7` | HR Reports & Analytics | Both | ⬜ Pending |

### P1: Staff Master & HR Records

**Status:** ⬜ Pending

#### `F.P1.1` — Staff Profile

##### `T.P1.1.1` — Create Staff Profile

**Sub-Tasks:**

- `ST.P1.1.1.1` Enter personal details
- `ST.P1.1.1.2` Upload documents (ID, certificates)
- `ST.P1.1.1.3` Assign employee code

##### `T.P1.1.2` — Edit Staff Profile

**Sub-Tasks:**

- `ST.P1.1.2.1` Update contact details
- `ST.P1.1.2.2` Manage emergency contacts

#### `F.P1.2` — Job & Employment Details

##### `T.P1.2.1` — Set Employment Details

**Sub-Tasks:**

- `ST.P1.2.1.1` Define designation & department
- `ST.P1.2.1.2` Set joining date & contract type

##### `T.P1.2.2` — Document Management

**Sub-Tasks:**

- `ST.P1.2.2.1` Upload appointment letter
- `ST.P1.2.2.2` Track document renewal dates

**Suggested DB Tables for `P1` — Staff Master & HR Records:**

- `staff_profiles`
- `employment_details`
- `staff_documents`

**Key API Endpoints for `P1`:**

```
GET    /api/v1/staff-profile           # List / index
POST   /api/v1/staff-profile           # Create
GET    /api/v1/staff-profile/{id}    # Show
PUT    /api/v1/staff-profile/{id}    # Update
DELETE /api/v1/staff-profile/{id}    # Delete
GET    /api/v1/job---employment-details           # List / index
POST   /api/v1/job---employment-details           # Create
GET    /api/v1/job---employment-details/{id}    # Show
PUT    /api/v1/job---employment-details/{id}    # Update
DELETE /api/v1/job---employment-details/{id}    # Delete
```

### P2: Staff Attendance & Leave

**Status:** ⬜ Pending

#### `F.P2.1` — Leave Management

##### `T.P2.1.1` — Apply Leave

**Sub-Tasks:**

- `ST.P2.1.1.1` Select leave type
- `ST.P2.1.1.2` Submit leave request
- `ST.P2.1.1.3` Attach supporting document

##### `T.P2.1.2` — Leave Approval

**Sub-Tasks:**

- `ST.P2.1.2.1` Approve/Reject leave
- `ST.P2.1.2.2` Record remarks with history

#### `F.P2.2` — Attendance Integration

##### `T.P2.2.1` — Sync Biometric Attendance

**Sub-Tasks:**

- `ST.P2.2.1.1` Fetch logs from biometric device
- `ST.P2.2.1.2` Auto-mark attendance

**Suggested DB Tables for `P2` — Staff Attendance & Leave:**

- `staff_attendances`
- `staff_leaves`
- `leave_types`
- `biometric_logs`

**Key API Endpoints for `P2`:**

```
GET    /api/v1/leave-management           # List / index
POST   /api/v1/leave-management           # Create
GET    /api/v1/leave-management/{id}    # Show
PUT    /api/v1/leave-management/{id}    # Update
DELETE /api/v1/leave-management/{id}    # Delete
GET    /api/v1/attendance-integration           # List / index
POST   /api/v1/attendance-integration           # Create
GET    /api/v1/attendance-integration/{id}    # Show
PUT    /api/v1/attendance-integration/{id}    # Update
DELETE /api/v1/attendance-integration/{id}    # Delete
```

### P3: Payroll Preparation

**Status:** ⬜ Pending

#### `F.P3.1` — Salary Configuration

##### `T.P3.1.1` — Define Salary Structure

**Sub-Tasks:**

- `ST.P3.1.1.1` Add earnings & deductions
- `ST.P3.1.1.2` Assign pay grade

##### `T.P3.1.2` — CTC Breakdown

**Sub-Tasks:**

- `ST.P3.1.2.1` Auto-calculate components
- `ST.P3.1.2.2` Record employer contributions

#### `F.P3.2` — Monthly Payroll

##### `T.P3.2.1` — Generate Payroll

**Sub-Tasks:**

- `ST.P3.2.1.1` Calculate earnings & deductions
- `ST.P3.2.1.2` Apply LOP for absences

##### `T.P3.2.2` — Payroll Adjustments

**Sub-Tasks:**

- `ST.P3.2.2.1` Add ad-hoc allowances
- `ST.P3.2.2.2` Apply manual deductions

**Suggested DB Tables for `P3` — Payroll Preparation:**

- `salary_structures`
- `payroll_months`
- `employee_payslips`
- `salary_components`

**Key API Endpoints for `P3`:**

```
GET    /api/v1/salary-configuration           # List / index
POST   /api/v1/salary-configuration           # Create
GET    /api/v1/salary-configuration/{id}    # Show
PUT    /api/v1/salary-configuration/{id}    # Update
DELETE /api/v1/salary-configuration/{id}    # Delete
GET    /api/v1/monthly-payroll           # List / index
POST   /api/v1/monthly-payroll           # Create
GET    /api/v1/monthly-payroll/{id}    # Show
PUT    /api/v1/monthly-payroll/{id}    # Update
DELETE /api/v1/monthly-payroll/{id}    # Delete
```

### P4: Compliance & Statutory Management

**Status:** ⬜ Pending

#### `F.P4.1` — Statutory Records

##### `T.P4.1.1` — PF & ESI Setup

**Sub-Tasks:**

- `ST.P4.1.1.1` Enable PF/ESI applicability
- `ST.P4.1.1.2` Record employee PF details

##### `T.P4.1.2` — Generate Statutory Reports

**Sub-Tasks:**

- `ST.P4.1.2.1` PF report
- `ST.P4.1.2.2` ESI contribution report

**Suggested DB Tables for `P4` — Compliance & Statutory Management:**

- `pf_esi_configs`
- `statutory_reports`

**Key API Endpoints for `P4`:**

```
GET    /api/v1/statutory-records           # List / index
POST   /api/v1/statutory-records           # Create
GET    /api/v1/statutory-records/{id}    # Show
PUT    /api/v1/statutory-records/{id}    # Update
DELETE /api/v1/statutory-records/{id}    # Delete
```

### P5: Performance Appraisal

**Status:** ⬜ Pending

#### `F.P5.1` — Appraisal Setup

##### `T.P5.1.1` — Define KPI Templates

**Sub-Tasks:**

- `ST.P5.1.1.1` Add KPI categories
- `ST.P5.1.1.2` Set weightage for each KPI

##### `T.P5.1.2` — Assign Appraisal Cycle

**Sub-Tasks:**

- `ST.P5.1.2.1` Set appraisal period
- `ST.P5.1.2.2` Assign reviewer

#### `F.P5.2` — Appraisal Execution

##### `T.P5.2.1` — Self Appraisal

**Sub-Tasks:**

- `ST.P5.2.1.1` Staff fills self-assessment
- `ST.P5.2.1.2` Attach proofs

##### `T.P5.2.2` — Manager Review

**Sub-Tasks:**

- `ST.P5.2.2.1` Score KPIs
- `ST.P5.2.2.2` Provide final rating

**Suggested DB Tables for `P5` — Performance Appraisal:**

- `kpi_templates`
- `appraisal_cycles`
- `employee_appraisals`

**Key API Endpoints for `P5`:**

```
GET    /api/v1/appraisal-setup           # List / index
POST   /api/v1/appraisal-setup           # Create
GET    /api/v1/appraisal-setup/{id}    # Show
PUT    /api/v1/appraisal-setup/{id}    # Update
DELETE /api/v1/appraisal-setup/{id}    # Delete
GET    /api/v1/appraisal-execution           # List / index
POST   /api/v1/appraisal-execution           # Create
GET    /api/v1/appraisal-execution/{id}    # Show
PUT    /api/v1/appraisal-execution/{id}    # Update
DELETE /api/v1/appraisal-execution/{id}    # Delete
```

### P6: Staff Training & Development

**Status:** ⬜ Pending

#### `F.P6.1` — Training Programs

##### `T.P6.1.1` — Create Training Program

**Sub-Tasks:**

- `ST.P6.1.1.1` Set topic & trainer
- `ST.P6.1.1.2` Define training schedule

##### `T.P6.1.2` — Enroll Staff

**Sub-Tasks:**

- `ST.P6.1.2.1` Add staff to training
- `ST.P6.1.2.2` Notify participants

#### `F.P6.2` — Training Evaluation

##### `T.P6.2.1` — Collect Feedback

**Sub-Tasks:**

- `ST.P6.2.1.1` Receive training feedback
- `ST.P6.2.1.2` Generate evaluation report

**Suggested DB Tables for `P6` — Staff Training & Development:**

- `training_programs`
- `training_enrollments`
- `training_feedback`

**Key API Endpoints for `P6`:**

```
GET    /api/v1/training-programs           # List / index
POST   /api/v1/training-programs           # Create
GET    /api/v1/training-programs/{id}    # Show
PUT    /api/v1/training-programs/{id}    # Update
DELETE /api/v1/training-programs/{id}    # Delete
GET    /api/v1/training-evaluation           # List / index
POST   /api/v1/training-evaluation           # Create
GET    /api/v1/training-evaluation/{id}    # Show
PUT    /api/v1/training-evaluation/{id}    # Update
DELETE /api/v1/training-evaluation/{id}    # Delete
```

### P7: HR Reports & Analytics

**Status:** ⬜ Pending

#### `F.P7.1` — Reports

##### `T.P7.1.1` — Generate Staff Reports

**Sub-Tasks:**

- `ST.P7.1.1.1` Staff register
- `ST.P7.1.1.2` Department-wise strength report

#### `F.P7.2` — Analytics

##### `T.P7.2.1` — HR Insights

**Sub-Tasks:**

- `ST.P7.2.1.1` Attrition rate analysis
- `ST.P7.2.1.2` Leave trend analysis

**Suggested DB Tables for `P7` — HR Reports & Analytics:**

- `staff_profiles`
- `employment_details`
- `staff_documents`

**Key API Endpoints for `P7`:**

```
GET    /api/v1/reports           # List / index
POST   /api/v1/reports           # Create
GET    /api/v1/reports/{id}    # Show
PUT    /api/v1/reports/{id}    # Update
DELETE /api/v1/reports/{id}    # Delete
GET    /api/v1/analytics           # List / index
POST   /api/v1/analytics           # Create
GET    /api/v1/analytics/{id}    # Show
PUT    /api/v1/analytics/{id}    # Update
DELETE /api/v1/analytics/{id}    # Delete
```

### Screen Design Requirements — Module P


### Report Requirements — Module P

- **Reports**: Tabular report with date range filter, export to PDF/Excel/CSV
- **Analytics**: Tabular report with date range filter, export to PDF/Excel/CSV

### Test Case Requirements — Module P

| Test Type | Scope |
|---|---|
| **Unit Tests** | All service classes and model methods in Module P |
| **Feature Tests** | All API endpoints — happy path, validation errors, auth failures |
| **Browser Tests** | Form submissions, list pagination, filter/search, export |
| **Functional Tests** | End-to-end business workflows (e.g., create → approve → complete lifecycle) |

---

## Module Q: Communication & Messaging

| | |
|---|---|
| **Module Code** | `Q` |
| **App Type** | Both |
| **Description** | Email, SMS, push notifications, in-app chat, announcements, emergency alerts, analytics. |
| **Total Sub-Modules** | 7 |
| **Total Features (Tasks)** | 22 |
| **Total Sub-Tasks** | 44 |

### Sub-Module Status

| Sub-Mod Code | Sub-Module Name | App Type | Status |
|---|---|---|---|
| `Q1` | Email Communication | Both | ✅ Completed 100% |
| `Q2` | SMS Communication | Both | ✅ Completed 60% |
| `Q3` | Push Notification System | Both | ✅ Completed 100% |
| `Q4` | In-App Messaging | Both | ✅ Completed 100% |
| `Q5` | Announcement & Notice Board | Both | ✅ Completed 100% |
| `Q6` | Emergency Alerts | Both | ✅ Completed 25% |
| `Q7` | Communication Reports & Analytics | Both | ✅ Completed 40% |

### Q1: Email Communication

**Status:** ✅ Completed 100%

#### `F.Q1.1` — Email Sending

##### `T.Q1.1.1` — Compose Email

**Sub-Tasks:**

- `ST.Q1.1.1.1` Select recipients (students/parents/staff)
- `ST.Q1.1.1.2` Add subject, body & attachments

##### `T.Q1.1.2` — Email Scheduling

**Sub-Tasks:**

- `ST.Q1.1.2.1` Schedule email for later
- `ST.Q1.1.2.2` Set recurring email rules

#### `F.Q1.2` — Template Management

##### `T.Q1.2.1` — Create Email Template

**Sub-Tasks:**

- `ST.Q1.2.1.1` Define template name
- `ST.Q1.2.1.2` Add placeholders for merge fields

##### `T.Q1.2.2` — Manage Templates

**Sub-Tasks:**

- `ST.Q1.2.2.1` Edit template content
- `ST.Q1.2.2.2` Activate/Deactivate template

**Suggested DB Tables for `Q1` — Email Communication:**

- `communication_logs`
- `email_templates`
- `sms_templates`
- `notification_logs`

**Key API Endpoints for `Q1`:**

```
GET    /api/v1/email-sending           # List / index
POST   /api/v1/email-sending           # Create
GET    /api/v1/email-sending/{id}    # Show
PUT    /api/v1/email-sending/{id}    # Update
DELETE /api/v1/email-sending/{id}    # Delete
GET    /api/v1/template-management           # List / index
POST   /api/v1/template-management           # Create
GET    /api/v1/template-management/{id}    # Show
PUT    /api/v1/template-management/{id}    # Update
DELETE /api/v1/template-management/{id}    # Delete
```

### Q2: SMS Communication

**Status:** ✅ Completed 60%

#### `F.Q2.1` — SMS Sending

##### `T.Q2.1.1` — Compose SMS

**Sub-Tasks:**

- `ST.Q2.1.1.1` Select recipients
- `ST.Q2.1.1.2` Write SMS within character limit

##### `T.Q2.1.2` — Bulk SMS

**Sub-Tasks:**

- `ST.Q2.1.2.1` Upload CSV for bulk recipients
- `ST.Q2.1.2.2` Validate phone numbers

#### `F.Q2.2` — SMS Gateway Integration

##### `T.Q2.2.1` — Configure Gateway

**Sub-Tasks:**

- `ST.Q2.2.1.1` Add API key & sender ID
- `ST.Q2.2.1.2` Test SMS delivery

##### `T.Q2.2.2` — Monitor SMS Logs

**Sub-Tasks:**

- `ST.Q2.2.2.1` Track SMS delivery status
- `ST.Q2.2.2.2` Export SMS logs

**Suggested DB Tables for `Q2` — SMS Communication:**

- `communication_logs`
- `email_templates`
- `sms_templates`
- `notification_logs`

**Key API Endpoints for `Q2`:**

```
GET    /api/v1/sms-sending           # List / index
POST   /api/v1/sms-sending           # Create
GET    /api/v1/sms-sending/{id}    # Show
PUT    /api/v1/sms-sending/{id}    # Update
DELETE /api/v1/sms-sending/{id}    # Delete
GET    /api/v1/sms-gateway-integration           # List / index
POST   /api/v1/sms-gateway-integration           # Create
GET    /api/v1/sms-gateway-integration/{id}    # Show
PUT    /api/v1/sms-gateway-integration/{id}    # Update
DELETE /api/v1/sms-gateway-integration/{id}    # Delete
```

### Q3: Push Notification System

**Status:** ✅ Completed 100%

#### `F.Q3.1` — Push Notification Sending

##### `T.Q3.1.1` — Send Notification

**Sub-Tasks:**

- `ST.Q3.1.1.1` Select notification category
- `ST.Q3.1.1.2` Add message & deep-link

##### `T.Q3.1.2` — Targeted Notifications

**Sub-Tasks:**

- `ST.Q3.1.2.1` Target specific classes/roles
- `ST.Q3.1.2.2` Set user filters

#### `F.Q3.2` — Mobile App Integration

##### `T.Q3.2.1` — App Token Sync

**Sub-Tasks:**

- `ST.Q3.2.1.1` Sync devices with FCM tokens
- `ST.Q3.2.1.2` Handle invalid tokens

**Suggested DB Tables for `Q3` — Push Notification System:**

- `notification_settings`
- `smtp_configs`
- `sms_gateway_configs`

**Key API Endpoints for `Q3`:**

```
GET    /api/v1/push-notification-sending           # List / index
POST   /api/v1/push-notification-sending           # Create
GET    /api/v1/push-notification-sending/{id}    # Show
PUT    /api/v1/push-notification-sending/{id}    # Update
DELETE /api/v1/push-notification-sending/{id}    # Delete
GET    /api/v1/mobile-app-integration           # List / index
POST   /api/v1/mobile-app-integration           # Create
GET    /api/v1/mobile-app-integration/{id}    # Show
PUT    /api/v1/mobile-app-integration/{id}    # Update
DELETE /api/v1/mobile-app-integration/{id}    # Delete
```

### Q4: In-App Messaging

**Status:** ✅ Completed 100%

#### `F.Q4.1` — Chat Messaging

##### `T.Q4.1.1` — Send In-App Message

**Sub-Tasks:**

- `ST.Q4.1.1.1` Select user/group
- `ST.Q4.1.1.2` Send rich-text message

##### `T.Q4.1.2` — Chat Attachments

**Sub-Tasks:**

- `ST.Q4.1.2.1` Attach images/docs
- `ST.Q4.1.2.2` Set file size restrictions

#### `F.Q4.2` — Message Moderation

##### `T.Q4.2.1` — Monitor Chat

**Sub-Tasks:**

- `ST.Q4.2.1.1` Flag abusive messages
- `ST.Q4.2.1.2` Auto-delete flagged content

**Suggested DB Tables for `Q4` — In-App Messaging:**

- `meal_menus`
- `meal_orders`
- `kitchen_stock`

**Key API Endpoints for `Q4`:**

```
GET    /api/v1/chat-messaging           # List / index
POST   /api/v1/chat-messaging           # Create
GET    /api/v1/chat-messaging/{id}    # Show
PUT    /api/v1/chat-messaging/{id}    # Update
DELETE /api/v1/chat-messaging/{id}    # Delete
GET    /api/v1/message-moderation           # List / index
POST   /api/v1/message-moderation           # Create
GET    /api/v1/message-moderation/{id}    # Show
PUT    /api/v1/message-moderation/{id}    # Update
DELETE /api/v1/message-moderation/{id}    # Delete
```

### Q5: Announcement & Notice Board

**Status:** ✅ Completed 100%

#### `F.Q5.1` — Create Announcement

##### `T.Q5.1.1` — Add Notice

**Sub-Tasks:**

- `ST.Q5.1.1.1` Enter notice title & details
- `ST.Q5.1.1.2` Set expiry date

##### `T.Q5.1.2` — Attach Files

**Sub-Tasks:**

- `ST.Q5.1.2.1` Upload PDF/image
- `ST.Q5.1.2.2` Restrict file types

#### `F.Q5.2` — Audience Targeting

##### `T.Q5.2.1` — Select Audience

**Sub-Tasks:**

- `ST.Q5.2.1.1` Choose classes/roles
- `ST.Q5.2.1.2` Enable parent-only announcements

**Suggested DB Tables for `Q5` — Announcement & Notice Board:**

- `announcement_notice_board_master`
- `announcement_notice_board_transactions`
- `announcement_notice_board_logs`

**Key API Endpoints for `Q5`:**

```
GET    /api/v1/create-announcement           # List / index
POST   /api/v1/create-announcement           # Create
GET    /api/v1/create-announcement/{id}    # Show
PUT    /api/v1/create-announcement/{id}    # Update
DELETE /api/v1/create-announcement/{id}    # Delete
GET    /api/v1/audience-targeting           # List / index
POST   /api/v1/audience-targeting           # Create
GET    /api/v1/audience-targeting/{id}    # Show
PUT    /api/v1/audience-targeting/{id}    # Update
DELETE /api/v1/audience-targeting/{id}    # Delete
```

### Q6: Emergency Alerts

**Status:** ✅ Completed 25%

#### `F.Q6.1` — Alert Broadcast

##### `T.Q6.1.1` — Send Emergency Alert

**Sub-Tasks:**

- `ST.Q6.1.1.1` Select emergency type
- `ST.Q6.1.1.2` Trigger broadcast via SMS/Email/App

##### `T.Q6.1.2` — Alert Priority

**Sub-Tasks:**

- `ST.Q6.1.2.1` Mark as high-priority
- `ST.Q6.1.2.2` Override silent mode

#### `F.Q6.2` — Alert Logs

##### `T.Q6.2.1` — Record Alert History

**Sub-Tasks:**

- `ST.Q6.2.1.1` Store alert time & audience
- `ST.Q6.2.1.2` Track delivery results

**Suggested DB Tables for `Q6` — Emergency Alerts:**

- `emergency_alerts_master`
- `emergency_alerts_transactions`
- `emergency_alerts_logs`

**Key API Endpoints for `Q6`:**

```
GET    /api/v1/alert-broadcast           # List / index
POST   /api/v1/alert-broadcast           # Create
GET    /api/v1/alert-broadcast/{id}    # Show
PUT    /api/v1/alert-broadcast/{id}    # Update
DELETE /api/v1/alert-broadcast/{id}    # Delete
GET    /api/v1/alert-logs           # List / index
POST   /api/v1/alert-logs           # Create
GET    /api/v1/alert-logs/{id}    # Show
PUT    /api/v1/alert-logs/{id}    # Update
DELETE /api/v1/alert-logs/{id}    # Delete
```

### Q7: Communication Reports & Analytics

**Status:** ✅ Completed 40%

#### `F.Q7.1` — Message Reports

##### `T.Q7.1.1` — Generate Report

**Sub-Tasks:**

- `ST.Q7.1.1.1` View sent/failed messages
- `ST.Q7.1.1.2` Filter by date/module

#### `F.Q7.2` — Communication Analytics

##### `T.Q7.2.1` — Analyze Engagement

**Sub-Tasks:**

- `ST.Q7.2.1.1` Track open rates
- `ST.Q7.2.1.2` Identify low-engagement groups

**Suggested DB Tables for `Q7` — Communication Reports & Analytics:**

- `communication_logs`
- `email_templates`
- `sms_templates`
- `notification_logs`

**Key API Endpoints for `Q7`:**

```
GET    /api/v1/message-reports           # List / index
POST   /api/v1/message-reports           # Create
GET    /api/v1/message-reports/{id}    # Show
PUT    /api/v1/message-reports/{id}    # Update
DELETE /api/v1/message-reports/{id}    # Delete
GET    /api/v1/communication-analytics           # List / index
POST   /api/v1/communication-analytics           # Create
GET    /api/v1/communication-analytics/{id}    # Show
PUT    /api/v1/communication-analytics/{id}    # Update
DELETE /api/v1/communication-analytics/{id}    # Delete
```

### Screen Design Requirements — Module Q


### Report Requirements — Module Q

- **Alert Logs**: Tabular report with date range filter, export to PDF/Excel/CSV
- **Message Reports**: Tabular report with date range filter, export to PDF/Excel/CSV
- **Communication Analytics**: Tabular report with date range filter, export to PDF/Excel/CSV

### Test Case Requirements — Module Q

| Test Type | Scope |
|---|---|
| **Unit Tests** | All service classes and model methods in Module Q |
| **Feature Tests** | All API endpoints — happy path, validation errors, auth failures |
| **Browser Tests** | Form submissions, list pagination, filter/search, export |
| **Functional Tests** | End-to-end business workflows (e.g., create → approve → complete lifecycle) |

---

## Module R: Certificates, Docs & Identity

| | |
|---|---|
| **Module Code** | `R` |
| **App Type** | Both |
| **Description** | Certificate templates, request workflows, generation, DMS, ID cards, QR verification. |
| **Total Sub-Modules** | 7 |
| **Total Features (Tasks)** | 25 |
| **Total Sub-Tasks** | 52 |

### Sub-Module Status

| Sub-Mod Code | Sub-Module Name | App Type | Status |
|---|---|---|---|
| `R1` | Certificate Templates & Configuration | Both | ⬜ Pending |
| `R2` | Certificate Request Workflow | Both | ⬜ Pending |
| `R3` | Certificate Generation & Issuance | Both | ⬜ Pending |
| `R4` | Document Management System (DMS) | Both | ⬜ Pending |
| `R5` | Identity Card (ID Card) Management | Both | ✅ Completed 100% |
| `R6` | Verification & Authentication System | Both | ⬜ Pending |
| `R7` | Reports & Analytics | Both | ✅ Completed 100% |

### R1: Certificate Templates & Configuration

**Status:** ⬜ Pending

#### `F.R1.1` — Template Creation

##### `T.R1.1.1` — Create Certificate Template

**Sub-Tasks:**

- `ST.R1.1.1.1` Define layout (header, body, footer)
- `ST.R1.1.1.2` Add dynamic merge fields (name, class, DOB)
- `ST.R1.1.1.3` Upload school logo & seal

##### `T.R1.1.2` — Design Custom Templates

**Sub-Tasks:**

- `ST.R1.1.2.1` Set fonts/colors/borders
- `ST.R1.1.2.2` Add QR code for verification

#### `F.R1.2` — Template Management

##### `T.R1.2.1` — Version Control

**Sub-Tasks:**

- `ST.R1.2.1.1` Save multiple template versions
- `ST.R1.2.1.2` Restore older versions

##### `T.R1.2.2` — Template Assignment

**Sub-Tasks:**

- `ST.R1.2.2.1` Assign template to certificate type
- `ST.R1.2.2.2` Set permissions for usage

**Suggested DB Tables for `R1` — Certificate Templates & Configuration:**

- `certificate_templates`
- `certificate_requests`
- `certificates_issued`

**Key API Endpoints for `R1`:**

```
GET    /api/v1/template-creation           # List / index
POST   /api/v1/template-creation           # Create
GET    /api/v1/template-creation/{id}    # Show
PUT    /api/v1/template-creation/{id}    # Update
DELETE /api/v1/template-creation/{id}    # Delete
GET    /api/v1/template-management           # List / index
POST   /api/v1/template-management           # Create
GET    /api/v1/template-management/{id}    # Show
PUT    /api/v1/template-management/{id}    # Update
DELETE /api/v1/template-management/{id}    # Delete
```

### R2: Certificate Request Workflow

**Status:** ⬜ Pending

#### `F.R2.1` — Submission

##### `T.R2.1.1` — Request Certificate

**Sub-Tasks:**

- `ST.R2.1.1.1` Select certificate type
- `ST.R2.1.1.2` Enter purpose of request
- `ST.R2.1.1.3` Attach supporting documents

##### `T.R2.1.2` — Track Request

**Sub-Tasks:**

- `ST.R2.1.2.1` View request status
- `ST.R2.1.2.2` Receive updates via SMS/email

#### `F.R2.2` — Approval Process

##### `T.R2.2.1` — Review Request

**Sub-Tasks:**

- `ST.R2.2.1.1` Validate supporting documents
- `ST.R2.2.1.2` Check student eligibility

##### `T.R2.2.2` — Approve/Reject Request

**Sub-Tasks:**

- `ST.R2.2.2.1` Record approval remarks
- `ST.R2.2.2.2` Auto-notify student/parents

**Suggested DB Tables for `R2` — Certificate Request Workflow:**

- `certificate_templates`
- `certificate_requests`
- `certificates_issued`

**Key API Endpoints for `R2`:**

```
GET    /api/v1/submission           # List / index
POST   /api/v1/submission           # Create
GET    /api/v1/submission/{id}    # Show
PUT    /api/v1/submission/{id}    # Update
DELETE /api/v1/submission/{id}    # Delete
GET    /api/v1/approval-process           # List / index
POST   /api/v1/approval-process           # Create
GET    /api/v1/approval-process/{id}    # Show
PUT    /api/v1/approval-process/{id}    # Update
DELETE /api/v1/approval-process/{id}    # Delete
```

### R3: Certificate Generation & Issuance

**Status:** ⬜ Pending

#### `F.R3.1` — Auto Generation

##### `T.R3.1.1` — Generate Certificate

**Sub-Tasks:**

- `ST.R3.1.1.1` Auto-fill merge fields
- `ST.R3.1.1.2` Apply digital signature

##### `T.R3.1.2` — Bulk Generation

**Sub-Tasks:**

- `ST.R3.1.2.1` Generate certificates for batch
- `ST.R3.1.2.2` Download ZIP of certificates

#### `F.R3.2` — Issuing Process

##### `T.R3.2.1` — Print & Issue

**Sub-Tasks:**

- `ST.R3.2.1.1` Print certificate copy
- `ST.R3.2.1.2` Upload issuance receipt

##### `T.R3.2.2` — Record Issuance

**Sub-Tasks:**

- `ST.R3.2.2.1` Log certificate number
- `ST.R3.2.2.2` Track date of issue

**Suggested DB Tables for `R3` — Certificate Generation & Issuance:**

- `certificate_templates`
- `certificate_requests`
- `certificates_issued`

**Key API Endpoints for `R3`:**

```
GET    /api/v1/auto-generation           # List / index
POST   /api/v1/auto-generation           # Create
GET    /api/v1/auto-generation/{id}    # Show
PUT    /api/v1/auto-generation/{id}    # Update
DELETE /api/v1/auto-generation/{id}    # Delete
GET    /api/v1/issuing-process           # List / index
POST   /api/v1/issuing-process           # Create
GET    /api/v1/issuing-process/{id}    # Show
PUT    /api/v1/issuing-process/{id}    # Update
DELETE /api/v1/issuing-process/{id}    # Delete
```

### R4: Document Management System (DMS)

**Status:** ⬜ Pending

#### `F.R4.1` — Document Upload

##### `T.R4.1.1` — Upload Student Document

**Sub-Tasks:**

- `ST.R4.1.1.1` Upload PDFs/images
- `ST.R4.1.1.2` Select document category (TC, Migration, DOB)

##### `T.R4.1.2` — Bulk Upload

**Sub-Tasks:**

- `ST.R4.1.2.1` Upload documents via ZIP
- `ST.R4.1.2.2` Map files to students

#### `F.R4.2` — Document Verification

##### `T.R4.2.1` — Verify Documents

**Sub-Tasks:**

- `ST.R4.2.1.1` Review uploaded file
- `ST.R4.2.1.2` Update verification status

##### `T.R4.2.2` — DMS Permissions

**Sub-Tasks:**

- `ST.R4.2.2.1` Set access restrictions
- `ST.R4.2.2.2` Track who viewed/downloaded document

**Suggested DB Tables for `R4` — Document Management System (DMS):**

- `student_documents`
- `document_verifications`

**Key API Endpoints for `R4`:**

```
GET    /api/v1/document-upload           # List / index
POST   /api/v1/document-upload           # Create
GET    /api/v1/document-upload/{id}    # Show
PUT    /api/v1/document-upload/{id}    # Update
DELETE /api/v1/document-upload/{id}    # Delete
GET    /api/v1/document-verification           # List / index
POST   /api/v1/document-verification           # Create
GET    /api/v1/document-verification/{id}    # Show
PUT    /api/v1/document-verification/{id}    # Update
DELETE /api/v1/document-verification/{id}    # Delete
```

### R5: Identity Card (ID Card) Management

**Status:** ✅ Completed 100%

#### `F.R5.1` — ID Card Templates

##### `T.R5.1.1` — Design ID Card Template

**Sub-Tasks:**

- `ST.R5.1.1.1` Add student photo field
- `ST.R5.1.1.2` Set barcode/QR code placement

##### `T.R5.1.2` — Template Versions

**Sub-Tasks:**

- `ST.R5.1.2.1` Save multiple ID formats
- `ST.R5.1.2.2` Assign format to class/department

#### `F.R5.2` — ID Card Generation

##### `T.R5.2.1` — Generate ID Card

**Sub-Tasks:**

- `ST.R5.2.1.1` Auto-fetch student details
- `ST.R5.2.1.2` Apply template layout

##### `T.R5.2.2` — Print & Distribution

**Sub-Tasks:**

- `ST.R5.2.2.1` Generate printable sheet
- `ST.R5.2.2.2` Track ID card handover

**Suggested DB Tables for `R5` — Identity Card (ID Card) Management:**

- `id_card_templates`
- `id_cards`

**Key API Endpoints for `R5`:**

```
GET    /api/v1/id-card-templates           # List / index
POST   /api/v1/id-card-templates           # Create
GET    /api/v1/id-card-templates/{id}    # Show
PUT    /api/v1/id-card-templates/{id}    # Update
DELETE /api/v1/id-card-templates/{id}    # Delete
GET    /api/v1/id-card-generation           # List / index
POST   /api/v1/id-card-generation           # Create
GET    /api/v1/id-card-generation/{id}    # Show
PUT    /api/v1/id-card-generation/{id}    # Update
DELETE /api/v1/id-card-generation/{id}    # Delete
```

### R6: Verification & Authentication System

**Status:** ⬜ Pending

#### `F.R6.1` — QR Code Verification

##### `T.R6.1.1` — Scan QR

**Sub-Tasks:**

- `ST.R6.1.1.1` Fetch certificate details
- `ST.R6.1.1.2` Show authenticity status

##### `T.R6.1.2` — Verification Logs

**Sub-Tasks:**

- `ST.R6.1.2.1` Record verification attempts
- `ST.R6.1.2.2` Track verification source

#### `F.R6.2` — API Verification

##### `T.R6.2.1` — Generate Verification API

**Sub-Tasks:**

- `ST.R6.2.1.1` Create API for third-party checks
- `ST.R6.2.1.2` Secure API with key

**Suggested DB Tables for `R6` — Verification & Authentication System:**

- `auth_policies`
- `login_attempts`
- `sso_configurations`

**Key API Endpoints for `R6`:**

```
GET    /api/v1/qr-code-verification           # List / index
POST   /api/v1/qr-code-verification           # Create
GET    /api/v1/qr-code-verification/{id}    # Show
PUT    /api/v1/qr-code-verification/{id}    # Update
DELETE /api/v1/qr-code-verification/{id}    # Delete
GET    /api/v1/api-verification           # List / index
POST   /api/v1/api-verification           # Create
GET    /api/v1/api-verification/{id}    # Show
PUT    /api/v1/api-verification/{id}    # Update
DELETE /api/v1/api-verification/{id}    # Delete
```

### R7: Reports & Analytics

**Status:** ✅ Completed 100%

#### `F.R7.1` — Certificate Reports

##### `T.R7.1.1` — Generate Reports

**Sub-Tasks:**

- `ST.R7.1.1.1` Issued certificates report
- `ST.R7.1.1.2` Pending certificates report

#### `F.R7.2` — Usage Analytics

##### `T.R7.2.1` — Analyze Requests

**Sub-Tasks:**

- `ST.R7.2.1.1` Identify peak request periods
- `ST.R7.2.1.2` Detect frequently requested certificate types

**Suggested DB Tables for `R7` — Reports & Analytics:**

- `ml_model_configs`
- `prediction_results`
- `analytics_snapshots`

**Key API Endpoints for `R7`:**

```
GET    /api/v1/certificate-reports           # List / index
POST   /api/v1/certificate-reports           # Create
GET    /api/v1/certificate-reports/{id}    # Show
PUT    /api/v1/certificate-reports/{id}    # Update
DELETE /api/v1/certificate-reports/{id}    # Delete
GET    /api/v1/usage-analytics           # List / index
POST   /api/v1/usage-analytics           # Create
GET    /api/v1/usage-analytics/{id}    # Show
PUT    /api/v1/usage-analytics/{id}    # Update
DELETE /api/v1/usage-analytics/{id}    # Delete
```

### Screen Design Requirements — Module R


### Report Requirements — Module R

- **Certificate Reports**: Tabular report with date range filter, export to PDF/Excel/CSV
- **Usage Analytics**: Tabular report with date range filter, export to PDF/Excel/CSV

### Test Case Requirements — Module R

| Test Type | Scope |
|---|---|
| **Unit Tests** | All service classes and model methods in Module R |
| **Feature Tests** | All API endpoints — happy path, validation errors, auth failures |
| **Browser Tests** | Form submissions, list pagination, filter/search, export |
| **Functional Tests** | End-to-end business workflows (e.g., create → approve → complete lifecycle) |

---

## Module S: Learning Management System (LMS)

| | |
|---|---|
| **Module Code** | `S` |
| **App Type** | Both |
| **Description** | Courses, content, quizzes, assignments, question bank, progress tracking, certificates, adaptive learning. |
| **Total Sub-Modules** | 11 |
| **Total Features (Tasks)** | 26 |
| **Total Sub-Tasks** | 53 |

### Sub-Module Status

| Sub-Mod Code | Sub-Module Name | App Type | Status |
|---|---|---|---|
| `S1` | Course Management | Both | ✅ Completed 100% |
| `S10` | Micro-Credentials & Digital Badges | Both | ⬜ Not Started |
| `S11` | Offline Content & Sync | Both | ⬜ Not Started |
| `S2` | Content Management | Both | ✅ Completed 100% |
| `S3` | Assessment Management | Both | ✅ Completed 100% |
| `S4` | Question Bank Management | Both | ✅ Completed 100% |
| `S5` | Tracking & Progress Monitoring | Both | ⬜ Pending |
| `S6` | Certificates for Courses | Both | ⬜ Pending |
| `S7` | LMS Reports & Analytics | Both | ⬜ Pending |
| `S8` | Adaptive Learning & Recommendation Engine | Both | ⬜ Not Started |
| `S9` | Competency-Based Assessment | Both | ⬜ Not Started |

### S1: Course Management

**Status:** ✅ Completed 100%

#### `F.S1.1` — Course Setup

##### `T.S1.1.1` — Create Course

**Sub-Tasks:**

- `ST.S1.1.1.1` Enter course title & description
- `ST.S1.1.1.2` Assign subject & grade
- `ST.S1.1.1.3` Upload course cover image

##### `T.S1.1.2` — Course Structure

**Sub-Tasks:**

- `ST.S1.1.2.1` Create units & lessons
- `ST.S1.1.2.2` Define learning objectives

#### `F.S1.2` — Course Publishing

##### `T.S1.2.1` — Publish Course

**Sub-Tasks:**

- `ST.S1.2.1.1` Set course visibility
- `ST.S1.2.1.2` Notify assigned students

**Suggested DB Tables for `S1` — Course Management:**

- `courses`
- `course_modules`
- `lessons`
- `course_enrollments`

**Key API Endpoints for `S1`:**

```
GET    /api/v1/course-setup           # List / index
POST   /api/v1/course-setup           # Create
GET    /api/v1/course-setup/{id}    # Show
PUT    /api/v1/course-setup/{id}    # Update
DELETE /api/v1/course-setup/{id}    # Delete
GET    /api/v1/course-publishing           # List / index
POST   /api/v1/course-publishing           # Create
GET    /api/v1/course-publishing/{id}    # Show
PUT    /api/v1/course-publishing/{id}    # Update
DELETE /api/v1/course-publishing/{id}    # Delete
```

### S10: Micro-Credentials & Digital Badges

**Status:** ⬜ Not Started

#### `F.S10.1` — Badge Design & Issuance

##### `T.S10.1.1` — Design Digital Badge

**Sub-Tasks:**

- `ST.S10.1.1.1` Create badge image, name, and description
- `ST.S10.1.1.2` Define issuance criteria (e.g., complete course with 90%+ score)

##### `T.S10.1.2` — Auto-Issue & Display

**Sub-Tasks:**

- `ST.S10.1.2.1` Automatically award badge when student meets criteria
- `ST.S10.1.2.2` Display earned badges on student profile and enable Open Badges export

**Suggested DB Tables for `S10` — Micro-Credentials & Digital Badges:**

- `micro_credentials_digital_badg_master`
- `micro_credentials_digital_badg_transactions`
- `micro_credentials_digital_badg_logs`

**Key API Endpoints for `S10`:**

```
GET    /api/v1/badge-design---issuance           # List / index
POST   /api/v1/badge-design---issuance           # Create
GET    /api/v1/badge-design---issuance/{id}    # Show
PUT    /api/v1/badge-design---issuance/{id}    # Update
DELETE /api/v1/badge-design---issuance/{id}    # Delete
```

### S11: Offline Content & Sync

**Status:** ⬜ Not Started

#### `F.S11.1` — Offline Access

##### `T.S11.1.1` — Download for Offline

**Sub-Tasks:**

- `ST.S11.1.1.1` Allow students to mark lessons/videos for offline viewing
- `ST.S11.1.1.2` Store downloaded content encrypted on device

##### `T.S11.1.2` — Sync Progress

**Sub-Tasks:**

- `ST.S11.1.2.1` Track quiz attempts, progress made offline
- `ST.S11.1.2.2` Auto-sync data when device reconnects to internet

**Suggested DB Tables for `S11` — Offline Content & Sync:**

- `learning_contents`
- `content_tags`

**Key API Endpoints for `S11`:**

```
GET    /api/v1/offline-access           # List / index
POST   /api/v1/offline-access           # Create
GET    /api/v1/offline-access/{id}    # Show
PUT    /api/v1/offline-access/{id}    # Update
DELETE /api/v1/offline-access/{id}    # Delete
```

### S2: Content Management

**Status:** ✅ Completed 100%

#### `F.S2.1` — Content Upload

##### `T.S2.1.1` — Upload Learning Content

**Sub-Tasks:**

- `ST.S2.1.1.1` Upload PDF/Video/SCORM
- `ST.S2.1.1.2` Add metadata & tags

#### `F.S2.2` — Content Organization

##### `T.S2.2.1` — Organize Content

**Sub-Tasks:**

- `ST.S2.2.1.1` Drag & drop content ordering
- `ST.S2.2.1.2` Assign content to lessons

**Suggested DB Tables for `S2` — Content Management:**

- `learning_contents`
- `content_tags`

**Key API Endpoints for `S2`:**

```
GET    /api/v1/content-upload           # List / index
POST   /api/v1/content-upload           # Create
GET    /api/v1/content-upload/{id}    # Show
PUT    /api/v1/content-upload/{id}    # Update
DELETE /api/v1/content-upload/{id}    # Delete
GET    /api/v1/content-organization           # List / index
POST   /api/v1/content-organization           # Create
GET    /api/v1/content-organization/{id}    # Show
PUT    /api/v1/content-organization/{id}    # Update
DELETE /api/v1/content-organization/{id}    # Delete
```

### S3: Assessment Management

**Status:** ✅ Completed 100%

#### `F.S3.1` — Quiz Builder

##### `T.S3.1.1` — Create Quiz

**Sub-Tasks:**

- `ST.S3.1.1.1` Add MCQ/True-False/Short answer
- `ST.S3.1.1.2` Set marks & difficulty level

##### `T.S3.1.2` — Quiz Settings

**Sub-Tasks:**

- `ST.S3.1.2.1` Set time limit
- `ST.S3.1.2.2` Randomize questions

#### `F.S3.2` — Assignment Management

##### `T.S3.2.1` — Create Assignment

**Sub-Tasks:**

- `ST.S3.2.1.1` Upload instructions
- `ST.S3.2.1.2` Set submission deadline

##### `T.S3.2.2` — Grade Assignment

**Sub-Tasks:**

- `ST.S3.2.2.1` Review submissions
- `ST.S3.2.2.2` Provide scoring & feedback

**Suggested DB Tables for `S3` — Assessment Management:**

- `quizzes`
- `questions`
- `question_bank`
- `quiz_attempts`
- `quiz_results`

**Key API Endpoints for `S3`:**

```
GET    /api/v1/quiz-builder           # List / index
POST   /api/v1/quiz-builder           # Create
GET    /api/v1/quiz-builder/{id}    # Show
PUT    /api/v1/quiz-builder/{id}    # Update
DELETE /api/v1/quiz-builder/{id}    # Delete
GET    /api/v1/assignment-management           # List / index
POST   /api/v1/assignment-management           # Create
GET    /api/v1/assignment-management/{id}    # Show
PUT    /api/v1/assignment-management/{id}    # Update
DELETE /api/v1/assignment-management/{id}    # Delete
```

### S4: Question Bank Management

**Status:** ✅ Completed 100%

#### `F.S4.1` — Question Entry

##### `T.S4.1.1` — Add Questions

**Sub-Tasks:**

- `ST.S4.1.1.1` Create MCQ/Descriptive questions
- `ST.S4.1.1.2` Tag difficulty & skill

##### `T.S4.1.2` — Bulk Upload

**Sub-Tasks:**

- `ST.S4.1.2.1` Upload questions via Excel
- `ST.S4.1.2.2` Map question fields

**Suggested DB Tables for `S4` — Question Bank Management:**

- `bank_accounts`
- `bank_reconciliations`
- `cash_books`

**Key API Endpoints for `S4`:**

```
GET    /api/v1/question-entry           # List / index
POST   /api/v1/question-entry           # Create
GET    /api/v1/question-entry/{id}    # Show
PUT    /api/v1/question-entry/{id}    # Update
DELETE /api/v1/question-entry/{id}    # Delete
```

### S5: Tracking & Progress Monitoring

**Status:** ⬜ Pending

#### `F.S5.1` — Learning Progress

##### `T.S5.1.1` — Track Lesson Completion

**Sub-Tasks:**

- `ST.S5.1.1.1` Record lesson viewed
- `ST.S5.1.1.2` Track time spent

#### `F.S5.2` — Assessment Analytics

##### `T.S5.2.1` — Generate Performance Report

**Sub-Tasks:**

- `ST.S5.2.1.1` Analyze quiz scores
- `ST.S5.2.1.2` Identify weak areas

**Suggested DB Tables for `S5` — Tracking & Progress Monitoring:**

- `audit_logs`
- `system_events`

**Key API Endpoints for `S5`:**

```
GET    /api/v1/learning-progress           # List / index
POST   /api/v1/learning-progress           # Create
GET    /api/v1/learning-progress/{id}    # Show
PUT    /api/v1/learning-progress/{id}    # Update
DELETE /api/v1/learning-progress/{id}    # Delete
GET    /api/v1/assessment-analytics           # List / index
POST   /api/v1/assessment-analytics           # Create
GET    /api/v1/assessment-analytics/{id}    # Show
PUT    /api/v1/assessment-analytics/{id}    # Update
DELETE /api/v1/assessment-analytics/{id}    # Delete
```

### S6: Certificates for Courses

**Status:** ⬜ Pending

#### `F.S6.1` — Certificate Rules

##### `T.S6.1.1` — Set Course Completion Criteria

**Sub-Tasks:**

- `ST.S6.1.1.1` Define passing marks
- `ST.S6.1.1.2` Enable minimum lesson completion

#### `F.S6.2` — Certificate Generation

##### `T.S6.2.1` — Generate Certificate

**Sub-Tasks:**

- `ST.S6.2.1.1` Populate student details
- `ST.S6.2.1.2` Apply LMS certificate template

**Suggested DB Tables for `S6` — Certificates for Courses:**

- `certificate_templates`
- `certificate_requests`
- `certificates_issued`

**Key API Endpoints for `S6`:**

```
GET    /api/v1/certificate-rules           # List / index
POST   /api/v1/certificate-rules           # Create
GET    /api/v1/certificate-rules/{id}    # Show
PUT    /api/v1/certificate-rules/{id}    # Update
DELETE /api/v1/certificate-rules/{id}    # Delete
GET    /api/v1/certificate-generation           # List / index
POST   /api/v1/certificate-generation           # Create
GET    /api/v1/certificate-generation/{id}    # Show
PUT    /api/v1/certificate-generation/{id}    # Update
DELETE /api/v1/certificate-generation/{id}    # Delete
```

### S7: LMS Reports & Analytics

**Status:** ⬜ Pending

#### `F.S7.1` — Reports

##### `T.S7.1.1` — Course Reports

**Sub-Tasks:**

- `ST.S7.1.1.1` Course-wise completion report
- `ST.S7.1.1.2` Student participation report

#### `F.S7.2` — AI Insights

##### `T.S7.2.1` — Engagement Predictions

**Sub-Tasks:**

- `ST.S7.2.1.1` Predict risk of drop-off
- `ST.S7.2.1.2` Recommend intervention

**Suggested DB Tables for `S7` — LMS Reports & Analytics:**

- `courses`
- `course_modules`
- `lessons`
- `course_enrollments`

**Key API Endpoints for `S7`:**

```
GET    /api/v1/reports           # List / index
POST   /api/v1/reports           # Create
GET    /api/v1/reports/{id}    # Show
PUT    /api/v1/reports/{id}    # Update
DELETE /api/v1/reports/{id}    # Delete
GET    /api/v1/ai-insights           # List / index
POST   /api/v1/ai-insights           # Create
GET    /api/v1/ai-insights/{id}    # Show
PUT    /api/v1/ai-insights/{id}    # Update
DELETE /api/v1/ai-insights/{id}    # Delete
```

### S8: Adaptive Learning & Recommendation Engine

**Status:** ⬜ Not Started

#### `F.S8.1` — Content Tagging & Profiling

##### `T.S8.1.1` — Tag Learning Resources

**Sub-Tasks:**

- `ST.S8.1.1.1` Tag videos, PDFs, quizzes with concepts, difficulty levels
- `ST.S8.1.1.2` Define pre-requisite and post-requisite relationships between resources

##### `T.S8.1.2` — Student Learning Profile

**Sub-Tasks:**

- `ST.S8.1.2.1` Build profile based on quiz scores, time spent, engagement
- `ST.S8.1.2.2` Identify knowledge gaps and mastered concepts

#### `F.S8.2` — AI Recommendations

##### `T.S8.2.1` — Generate Personalized Suggestions

**Sub-Tasks:**

- `ST.S8.2.1.1` Recommend "next best" lesson based on profile and goals
- `ST.S8.2.1.2` Suggest remedial content for weak areas and advanced content for mastery

**Suggested DB Tables for `S8` — Adaptive Learning & Recommendation Engine:**

- `adaptive_learning_recommendati_master`
- `adaptive_learning_recommendati_transactions`
- `adaptive_learning_recommendati_logs`

**Key API Endpoints for `S8`:**

```
GET    /api/v1/content-tagging---profiling           # List / index
POST   /api/v1/content-tagging---profiling           # Create
GET    /api/v1/content-tagging---profiling/{id}    # Show
PUT    /api/v1/content-tagging---profiling/{id}    # Update
DELETE /api/v1/content-tagging---profiling/{id}    # Delete
GET    /api/v1/ai-recommendations           # List / index
POST   /api/v1/ai-recommendations           # Create
GET    /api/v1/ai-recommendations/{id}    # Show
PUT    /api/v1/ai-recommendations/{id}    # Update
DELETE /api/v1/ai-recommendations/{id}    # Delete
```

### S9: Competency-Based Assessment

**Status:** ⬜ Not Started

#### `F.S9.1` — Rubric Management

##### `T.S9.1.1` — Create Assessment Rubric

**Sub-Tasks:**

- `ST.S9.1.1.1` Define competency dimensions and performance levels (Novice to Expert)
- `ST.S9.1.1.2` Attach rubric to assignments, projects, discussions

##### `T.S9.1.2` — Evidence-Based Assessment

**Sub-Tasks:**

- `ST.S9.1.2.1` Allow students to submit evidence (files, links) against rubric criteria
- `ST.S9.1.2.2` Enable teacher/peer evaluation using the rubric

**Suggested DB Tables for `S9` — Competency-Based Assessment:**

- `quizzes`
- `questions`
- `question_bank`
- `quiz_attempts`
- `quiz_results`

**Key API Endpoints for `S9`:**

```
GET    /api/v1/rubric-management           # List / index
POST   /api/v1/rubric-management           # Create
GET    /api/v1/rubric-management/{id}    # Show
PUT    /api/v1/rubric-management/{id}    # Update
DELETE /api/v1/rubric-management/{id}    # Delete
```

### Screen Design Requirements — Module S


### Report Requirements — Module S

- **Assessment Analytics**: Tabular report with date range filter, export to PDF/Excel/CSV
- **Reports**: Tabular report with date range filter, export to PDF/Excel/CSV

### Test Case Requirements — Module S

| Test Type | Scope |
|---|---|
| **Unit Tests** | All service classes and model methods in Module S |
| **Feature Tests** | All API endpoints — happy path, validation errors, auth failures |
| **Browser Tests** | Form submissions, list pagination, filter/search, export |
| **Functional Tests** | End-to-end business workflows (e.g., create → approve → complete lifecycle) |

---

## Module SYS: System Administration

| | |
|---|---|
| **Module Code** | `SYS` |
| **App Type** | Prime |
| **Description** | Platform health monitoring, API key management, webhook config, bulk data import/export. |
| **Total Sub-Modules** | 3 |
| **Total Features (Tasks)** | 6 |
| **Total Sub-Tasks** | 12 |

### Sub-Module Status

| Sub-Mod Code | Sub-Module Name | App Type | Status |
|---|---|---|---|
| `SYS1` | System Health Monitoring | Both | ⬜ Not Started |
| `SYS2` | API & Integration Management | Both | ⬜ Not Started |
| `SYS3` | Data Management | Both | ⬜ Not Started |

### SYS1: System Health Monitoring

**Status:** ⬜ Not Started

#### `F.SYS1.1` — Dashboard & Alerts

##### `T.SYS1.1.1` — Monitor System Metrics

**Sub-Tasks:**

- `ST.SYS1.1.1.1` Display real-time API response times, server CPU/RAM usage, disk space
- `ST.SYS1.1.1.2` Monitor background job queue (failed, pending jobs) and database connections

##### `T.SYS1.1.2` — Configure Alerts

**Sub-Tasks:**

- `ST.SYS1.1.2.1` Set thresholds for critical metrics (e.g., CPU >80% for 5 min)
- `ST.SYS1.1.2.2` Define alert channels (Email, Slack, SMS) for different severity levels

**Suggested DB Tables for `SYS1` — System Health Monitoring:**

- `audit_logs`
- `system_events`

**Key API Endpoints for `SYS1`:**

```
GET    /api/v1/dashboard---alerts           # List / index
POST   /api/v1/dashboard---alerts           # Create
GET    /api/v1/dashboard---alerts/{id}    # Show
PUT    /api/v1/dashboard---alerts/{id}    # Update
DELETE /api/v1/dashboard---alerts/{id}    # Delete
```

### SYS2: API & Integration Management

**Status:** ⬜ Not Started

#### `F.SYS2.1` — API Key Management

##### `T.SYS2.1.1` — Create & Manage API Keys

**Sub-Tasks:**

- `ST.SYS2.1.1.1` Generate API keys for third-party integrations (Biometric, Payment Gateway)
- `ST.SYS2.1.1.2` Set API key permissions, rate limits, and expiration dates

##### `T.SYS2.1.2` — Webhook Configuration

**Sub-Tasks:**

- `ST.SYS2.1.2.1` Configure endpoints to receive webhooks from external services
- `ST.SYS2.1.2.2` View webhook delivery logs and retry failed deliveries

**Suggested DB Tables for `SYS2` — API & Integration Management:**

- `api_integration_management_master`
- `api_integration_management_transactions`
- `api_integration_management_logs`

**Key API Endpoints for `SYS2`:**

```
GET    /api/v1/api-key-management           # List / index
POST   /api/v1/api-key-management           # Create
GET    /api/v1/api-key-management/{id}    # Show
PUT    /api/v1/api-key-management/{id}    # Update
DELETE /api/v1/api-key-management/{id}    # Delete
```

### SYS3: Data Management

**Status:** ⬜ Not Started

#### `F.SYS3.1` — Import/Export Wizards

##### `T.SYS3.1.1` — Bulk Data Import

**Sub-Tasks:**

- `ST.SYS3.1.1.1` Upload CSV/Excel files for students, staff, fees with field mapping
- `ST.SYS3.1.1.2` Validate data format, check for duplicates, and preview before import

##### `T.SYS3.1.2` — Data Export & Archival

**Sub-Tasks:**

- `ST.SYS3.1.2.1` Export data for specific modules (e.g., all fee transactions for a year)
- `ST.SYS3.1.2.2` Archive old academic year data to cold storage and update indexes

**Suggested DB Tables for `SYS3` — Data Management:**

- `data_management_master`
- `data_management_transactions`
- `data_management_logs`

**Key API Endpoints for `SYS3`:**

```
GET    /api/v1/import-export-wizards           # List / index
POST   /api/v1/import-export-wizards           # Create
GET    /api/v1/import-export-wizards/{id}    # Show
PUT    /api/v1/import-export-wizards/{id}    # Update
DELETE /api/v1/import-export-wizards/{id}    # Delete
```

### Screen Design Requirements — Module SYS


### Report Requirements — Module SYS

- **Import/Export Wizards**: Tabular report with date range filter, export to PDF/Excel/CSV

### Test Case Requirements — Module SYS

| Test Type | Scope |
|---|---|
| **Unit Tests** | All service classes and model methods in Module SYS |
| **Feature Tests** | All API endpoints — happy path, validation errors, auth failures |
| **Browser Tests** | Form submissions, list pagination, filter/search, export |
| **Functional Tests** | End-to-end business workflows (e.g., create → approve → complete lifecycle) |

---

## Module T: Learner Experience Platform (LXP)

| | |
|---|---|
| **Module Code** | `T` |
| **App Type** | Both |
| **Description** | Personalized learning paths, skill graphs, AI recommendations, goals, gamification, social learning. |
| **Total Sub-Modules** | 9 |
| **Total Features (Tasks)** | 23 |
| **Total Sub-Tasks** | 47 |

### Sub-Module Status

| Sub-Mod Code | Sub-Module Name | App Type | Status |
|---|---|---|---|
| `T1` | Personalized Learning Paths | Both | ⬜ Not Started |
| `T2` | Skill Graph & Competency Mapping | Both | ⬜ Not Started |
| `T3` | AI Recommendations Engine | Both | ⬜ Not Started |
| `T4` | Learning Goals & Roadmaps | Both | ⬜ Not Started |
| `T5` | Gamification & Engagement | Both | ⬜ Not Started |
| `T6` | Social Learning & Collaboration | Both | ⬜ Not Started |
| `T7` | Learning Analytics & Insights | Both | ⬜ Not Started |
| `T8` | Mentorship & Career Pathing | Both | ⬜ Not Started |
| `T9` | Personalized News & Activity Feed | Both | ⬜ Not Started |

### T1: Personalized Learning Paths

**Status:** ⬜ Not Started

#### `F.T1.1` — Path Creation

##### `T.T1.1.1` — Create Learning Path

**Sub-Tasks:**

- `ST.T1.1.1.1` Select goal or competency target
- `ST.T1.1.1.2` Add sequence of courses/lessons
- `ST.T1.1.1.3` Define prerequisites

##### `T.T1.1.2` — Path Customization

**Sub-Tasks:**

- `ST.T1.1.2.1` Allow learners to reorder items
- `ST.T1.1.2.2` Enable optional modules

#### `F.T1.2` — AI-Based Path Suggestions

##### `T.T1.2.1` — Generate Path Suggestions

**Sub-Tasks:**

- `ST.T1.2.1.1` Analyze learner profile & behavior
- `ST.T1.2.1.2` Recommend personalized path

**Suggested DB Tables for `T1` — Personalized Learning Paths:**

- `learning_paths`
- `path_items`
- `learner_paths`

**Key API Endpoints for `T1`:**

```
GET    /api/v1/path-creation           # List / index
POST   /api/v1/path-creation           # Create
GET    /api/v1/path-creation/{id}    # Show
PUT    /api/v1/path-creation/{id}    # Update
DELETE /api/v1/path-creation/{id}    # Delete
GET    /api/v1/ai-based-path-suggestions           # List / index
POST   /api/v1/ai-based-path-suggestions           # Create
GET    /api/v1/ai-based-path-suggestions/{id}    # Show
PUT    /api/v1/ai-based-path-suggestions/{id}    # Update
DELETE /api/v1/ai-based-path-suggestions/{id}    # Delete
```

### T2: Skill Graph & Competency Mapping

**Status:** ⬜ Not Started

#### `F.T2.1` — Skill Framework

##### `T.T2.1.1` — Define Skills

**Sub-Tasks:**

- `ST.T2.1.1.1` Add technical/cognitive/soft skills
- `ST.T2.1.1.2` Define skill hierarchy

##### `T.T2.1.2` — Map Skills to Content

**Sub-Tasks:**

- `ST.T2.1.2.1` Assign skills to lessons
- `ST.T2.1.2.2` Link assessments to competencies

#### `F.T2.2` — Skill Tracking

##### `T.T2.2.1` — Track Skill Growth

**Sub-Tasks:**

- `ST.T2.2.1.1` Update skill score after assessment
- `ST.T2.2.1.2` Generate skill radar chart

**Suggested DB Tables for `T2` — Skill Graph & Competency Mapping:**

- `skills`
- `skill_categories`
- `learner_skills`
- `skill_assessments`

**Key API Endpoints for `T2`:**

```
GET    /api/v1/skill-framework           # List / index
POST   /api/v1/skill-framework           # Create
GET    /api/v1/skill-framework/{id}    # Show
PUT    /api/v1/skill-framework/{id}    # Update
DELETE /api/v1/skill-framework/{id}    # Delete
GET    /api/v1/skill-tracking           # List / index
POST   /api/v1/skill-tracking           # Create
GET    /api/v1/skill-tracking/{id}    # Show
PUT    /api/v1/skill-tracking/{id}    # Update
DELETE /api/v1/skill-tracking/{id}    # Delete
```

### T3: AI Recommendations Engine

**Status:** ⬜ Not Started

#### `F.T3.1` — Content Recommendations

##### `T.T3.1.1` — Recommend Content

**Sub-Tasks:**

- `ST.T3.1.1.1` Use ML model to recommend next lesson
- `ST.T3.1.1.2` Rank recommendations based on relevance

#### `F.T3.2` — Peer-Based Recommendations

##### `T.T3.2.1` — Similar Learner Analysis

**Sub-Tasks:**

- `ST.T3.2.1.1` Identify similar learners
- `ST.T3.2.1.2` Suggest content based on peer success

**Suggested DB Tables for `T3` — AI Recommendations Engine:**

- `ai_recommendations_engine_master`
- `ai_recommendations_engine_transactions`
- `ai_recommendations_engine_logs`

**Key API Endpoints for `T3`:**

```
GET    /api/v1/content-recommendations           # List / index
POST   /api/v1/content-recommendations           # Create
GET    /api/v1/content-recommendations/{id}    # Show
PUT    /api/v1/content-recommendations/{id}    # Update
DELETE /api/v1/content-recommendations/{id}    # Delete
GET    /api/v1/peer-based-recommendations           # List / index
POST   /api/v1/peer-based-recommendations           # Create
GET    /api/v1/peer-based-recommendations/{id}    # Show
PUT    /api/v1/peer-based-recommendations/{id}    # Update
DELETE /api/v1/peer-based-recommendations/{id}    # Delete
```

### T4: Learning Goals & Roadmaps

**Status:** ⬜ Not Started

#### `F.T4.1` — Goal Setting

##### `T.T4.1.1` — Set Learning Goals

**Sub-Tasks:**

- `ST.T4.1.1.1` Learner chooses a goal
- `ST.T4.1.1.2` Define timeline for completion

#### `F.T4.2` — Goal Tracking

##### `T.T4.2.1` — Track Progress

**Sub-Tasks:**

- `ST.T4.2.1.1` View completion bar
- `ST.T4.2.1.2` Receive milestone reminders

**Suggested DB Tables for `T4` — Learning Goals & Roadmaps:**

- `learning_goals_roadmaps_master`
- `learning_goals_roadmaps_transactions`
- `learning_goals_roadmaps_logs`

**Key API Endpoints for `T4`:**

```
GET    /api/v1/goal-setting           # List / index
POST   /api/v1/goal-setting           # Create
GET    /api/v1/goal-setting/{id}    # Show
PUT    /api/v1/goal-setting/{id}    # Update
DELETE /api/v1/goal-setting/{id}    # Delete
GET    /api/v1/goal-tracking           # List / index
POST   /api/v1/goal-tracking           # Create
GET    /api/v1/goal-tracking/{id}    # Show
PUT    /api/v1/goal-tracking/{id}    # Update
DELETE /api/v1/goal-tracking/{id}    # Delete
```

### T5: Gamification & Engagement

**Status:** ⬜ Not Started

#### `F.T5.1` — Badges & Rewards

##### `T.T5.1.1` — Award Badges

**Sub-Tasks:**

- `ST.T5.1.1.1` Define badge criteria
- `ST.T5.1.1.2` Auto-award on achievement

#### `F.T5.2` — Leaderboards

##### `T.T5.2.1` — Generate Leaderboard

**Sub-Tasks:**

- `ST.T5.2.1.1` List top performers
- `ST.T5.2.1.2` Filter by class/subject

**Suggested DB Tables for `T5` — Gamification & Engagement:**

- `gamification_engagement_master`
- `gamification_engagement_transactions`
- `gamification_engagement_logs`

**Key API Endpoints for `T5`:**

```
GET    /api/v1/badges---rewards           # List / index
POST   /api/v1/badges---rewards           # Create
GET    /api/v1/badges---rewards/{id}    # Show
PUT    /api/v1/badges---rewards/{id}    # Update
DELETE /api/v1/badges---rewards/{id}    # Delete
GET    /api/v1/leaderboards           # List / index
POST   /api/v1/leaderboards           # Create
GET    /api/v1/leaderboards/{id}    # Show
PUT    /api/v1/leaderboards/{id}    # Update
DELETE /api/v1/leaderboards/{id}    # Delete
```

### T6: Social Learning & Collaboration

**Status:** ⬜ Not Started

#### `F.T6.1` — Discussion Forums

##### `T.T6.1.1` — Create Forum

**Sub-Tasks:**

- `ST.T6.1.1.1` Define discussion topic
- `ST.T6.1.1.2` Assign moderator

##### `T.T6.1.2` — Thread Management

**Sub-Tasks:**

- `ST.T6.1.2.1` Post comments
- `ST.T6.1.2.2` Upload attachments

#### `F.T6.2` — Peer Support

##### `T.T6.2.1` — Peer Mentoring

**Sub-Tasks:**

- `ST.T6.2.1.1` Assign mentors
- `ST.T6.2.1.2` Track mentoring sessions

**Suggested DB Tables for `T6` — Social Learning & Collaboration:**

- `social_learning_collaboration_master`
- `social_learning_collaboration_transactions`
- `social_learning_collaboration_logs`

**Key API Endpoints for `T6`:**

```
GET    /api/v1/discussion-forums           # List / index
POST   /api/v1/discussion-forums           # Create
GET    /api/v1/discussion-forums/{id}    # Show
PUT    /api/v1/discussion-forums/{id}    # Update
DELETE /api/v1/discussion-forums/{id}    # Delete
GET    /api/v1/peer-support           # List / index
POST   /api/v1/peer-support           # Create
GET    /api/v1/peer-support/{id}    # Show
PUT    /api/v1/peer-support/{id}    # Update
DELETE /api/v1/peer-support/{id}    # Delete
```

### T7: Learning Analytics & Insights

**Status:** ⬜ Not Started

#### `F.T7.1` — Engagement Analytics

##### `T.T7.1.1` — Track Engagement

**Sub-Tasks:**

- `ST.T7.1.1.1` Record time spent per lesson
- `ST.T7.1.1.2` Identify drop-off points

#### `F.T7.2` — AI Insights

##### `T.T7.2.1` — Predict Learning Outcomes

**Sub-Tasks:**

- `ST.T7.2.1.1` Use ML to predict performance
- `ST.T7.2.1.2` Generate early warning alerts

**Suggested DB Tables for `T7` — Learning Analytics & Insights:**

- `ml_model_configs`
- `prediction_results`
- `analytics_snapshots`

**Key API Endpoints for `T7`:**

```
GET    /api/v1/engagement-analytics           # List / index
POST   /api/v1/engagement-analytics           # Create
GET    /api/v1/engagement-analytics/{id}    # Show
PUT    /api/v1/engagement-analytics/{id}    # Update
DELETE /api/v1/engagement-analytics/{id}    # Delete
GET    /api/v1/ai-insights           # List / index
POST   /api/v1/ai-insights           # Create
GET    /api/v1/ai-insights/{id}    # Show
PUT    /api/v1/ai-insights/{id}    # Update
DELETE /api/v1/ai-insights/{id}    # Delete
```

### T8: Mentorship & Career Pathing

**Status:** ⬜ Not Started

#### `F.T8.1` — Mentorship Program Setup

##### `T.T8.1.1` — Create Mentorship Program

**Sub-Tasks:**

- `ST.T8.1.1.1` Define program goals, duration, and target audience
- `ST.T8.1.1.2` Set matching criteria (skills, interests, career goals)

##### `T.T8.1.2` — Mentor-Mentee Matching

**Sub-Tasks:**

- `ST.T8.1.2.1` Auto-suggest mentor-mentee pairs based on criteria
- `ST.T8.1.2.2` Allow manual override and approval of matches

#### `F.T8.2` — Mentorship Tracking

##### `T.T8.2.1` — Schedule & Log Sessions

**Sub-Tasks:**

- `ST.T8.2.1.1` Book sessions via integrated calendar
- `ST.T8.2.1.2` Log session notes, goals discussed, and action items

##### `T.T8.2.2` — Progress & Feedback

**Sub-Tasks:**

- `ST.T8.2.2.1` Track mentee progress towards defined goals
- `ST.T8.2.2.2` Collect feedback from both mentor and mentee post-program

**Suggested DB Tables for `T8` — Mentorship & Career Pathing:**

- `mentorship_career_pathing_master`
- `mentorship_career_pathing_transactions`
- `mentorship_career_pathing_logs`

**Key API Endpoints for `T8`:**

```
GET    /api/v1/mentorship-program-setup           # List / index
POST   /api/v1/mentorship-program-setup           # Create
GET    /api/v1/mentorship-program-setup/{id}    # Show
PUT    /api/v1/mentorship-program-setup/{id}    # Update
DELETE /api/v1/mentorship-program-setup/{id}    # Delete
GET    /api/v1/mentorship-tracking           # List / index
POST   /api/v1/mentorship-tracking           # Create
GET    /api/v1/mentorship-tracking/{id}    # Show
PUT    /api/v1/mentorship-tracking/{id}    # Update
DELETE /api/v1/mentorship-tracking/{id}    # Delete
```

### T9: Personalized News & Activity Feed

**Status:** ⬜ Not Started

#### `F.T9.1` — Feed Configuration

##### `T.T9.1.1` — Define Content Sources

**Sub-Tasks:**

- `ST.T9.1.1.1` Aggregate from announcements, new course materials, peer activity
- `ST.T9.1.1.2` Include mentor notes, achievement badges, group discussions

##### `T.T9.1.2` — Personalization Algorithm

**Sub-Tasks:**

- `ST.T9.1.2.1` Rank feed items based on user role, enrolled courses, interests
- `ST.T9.1.2.2` Prioritize unread/important items and filter out irrelevant content

**Suggested DB Tables for `T9` — Personalized News & Activity Feed:**

- `personalized_news_activity_fee_master`
- `personalized_news_activity_fee_transactions`
- `personalized_news_activity_fee_logs`

**Key API Endpoints for `T9`:**

```
GET    /api/v1/feed-configuration           # List / index
POST   /api/v1/feed-configuration           # Create
GET    /api/v1/feed-configuration/{id}    # Show
PUT    /api/v1/feed-configuration/{id}    # Update
DELETE /api/v1/feed-configuration/{id}    # Delete
```

### Screen Design Requirements — Module T


### Report Requirements — Module T

- **Engagement Analytics**: Tabular report with date range filter, export to PDF/Excel/CSV

### Test Case Requirements — Module T

| Test Type | Scope |
|---|---|
| **Unit Tests** | All service classes and model methods in Module T |
| **Feature Tests** | All API endpoints — happy path, validation errors, auth failures |
| **Browser Tests** | Form submissions, list pagination, filter/search, export |
| **Functional Tests** | End-to-end business workflows (e.g., create → approve → complete lifecycle) |

---

## Module U: Predictive Analytics & ML Engine

| | |
|---|---|
| **Module Code** | `U` |
| **App Type** | Both |
| **Description** | ML models for student risk, attendance forecasting, fee default prediction, skill gap, route optimization. |
| **Total Sub-Modules** | 9 |
| **Total Features (Tasks)** | 24 |
| **Total Sub-Tasks** | 51 |

### Sub-Module Status

| Sub-Mod Code | Sub-Module Name | App Type | Status |
|---|---|---|---|
| `U1` | Student Performance Prediction | Both | ⬜ Not Started |
| `U2` | Attendance Forecasting | Both | ⬜ Not Started |
| `U3` | Fee Default Prediction | Both | ⬜ Not Started |
| `U4` | Skill Gap Analysis | Both | ⬜ Not Started |
| `U5` | Transport Route Optimization | Both | ⬜ Not Started |
| `U6` | Resource Allocation Optimization | Both | ⬜ Not Started |
| `U7` | AI Dashboards & Visualization | Both | ⬜ Not Started |
| `U8` | Sentiment & Feedback Analysis | Both | ⬜ Not Started |
| `U9` | Institutional Benchmarking | Both | ⬜ Not Started |

### U1: Student Performance Prediction

**Status:** ⬜ Not Started

#### `F.U1.1` — Risk Prediction Models

##### `T.U1.1.1` — Predict Academic Risk

**Sub-Tasks:**

- `ST.U1.1.1.1` Analyze attendance, marks, engagement
- `ST.U1.1.1.2` Generate risk score for each student
- `ST.U1.1.1.3` Identify subjects with potential failure

##### `T.U1.1.2` — Early Warning Alerts

**Sub-Tasks:**

- `ST.U1.1.2.1` Trigger alerts for high-risk students
- `ST.U1.1.2.2` Send recommendations to teachers/parents

#### `F.U1.2` — Performance Insights

##### `T.U1.2.1` — Generate Insights

**Sub-Tasks:**

- `ST.U1.2.1.1` Identify weak concepts per student
- `ST.U1.2.1.2` Highlight performance trends

**Suggested DB Tables for `U1` — Student Performance Prediction:**

- `student_performance_prediction_master`
- `student_performance_prediction_transactions`
- `student_performance_prediction_logs`

**Key API Endpoints for `U1`:**

```
GET    /api/v1/risk-prediction-models           # List / index
POST   /api/v1/risk-prediction-models           # Create
GET    /api/v1/risk-prediction-models/{id}    # Show
PUT    /api/v1/risk-prediction-models/{id}    # Update
DELETE /api/v1/risk-prediction-models/{id}    # Delete
GET    /api/v1/performance-insights           # List / index
POST   /api/v1/performance-insights           # Create
GET    /api/v1/performance-insights/{id}    # Show
PUT    /api/v1/performance-insights/{id}    # Update
DELETE /api/v1/performance-insights/{id}    # Delete
```

### U2: Attendance Forecasting

**Status:** ⬜ Not Started

#### `F.U2.1` — Forecast Models

##### `T.U2.1.1` — Predict Absence Probability

**Sub-Tasks:**

- `ST.U2.1.1.1` Analyze past attendance & patterns
- `ST.U2.1.1.2` Predict likelihood of absence

##### `T.U2.1.2` — Suggest Interventions

**Sub-Tasks:**

- `ST.U2.1.2.1` Generate preventive recommendations
- `ST.U2.1.2.2` Notify class teachers

#### `F.U2.2` — Attendance Trends

##### `T.U2.2.1` — Trend Visualization

**Sub-Tasks:**

- `ST.U2.2.1.1` Plot weekly/monthly patterns
- `ST.U2.2.1.2` Highlight anomaly spikes

**Suggested DB Tables for `U2` — Attendance Forecasting:**

- `attendance_forecasting_master`
- `attendance_forecasting_transactions`
- `attendance_forecasting_logs`

**Key API Endpoints for `U2`:**

```
GET    /api/v1/forecast-models           # List / index
POST   /api/v1/forecast-models           # Create
GET    /api/v1/forecast-models/{id}    # Show
PUT    /api/v1/forecast-models/{id}    # Update
DELETE /api/v1/forecast-models/{id}    # Delete
GET    /api/v1/attendance-trends           # List / index
POST   /api/v1/attendance-trends           # Create
GET    /api/v1/attendance-trends/{id}    # Show
PUT    /api/v1/attendance-trends/{id}    # Update
DELETE /api/v1/attendance-trends/{id}    # Delete
```

### U3: Fee Default Prediction

**Status:** ⬜ Not Started

#### `F.U3.1` — Default Prediction Model

##### `T.U3.1.1` — Predict Fee Default Risk

**Sub-Tasks:**

- `ST.U3.1.1.1` Analyze payment history
- `ST.U3.1.1.2` Identify chronic late payers

##### `T.U3.1.2` — Automated Alerts

**Sub-Tasks:**

- `ST.U3.1.2.1` Notify accounts department
- `ST.U3.1.2.2` Send automated reminders

#### `F.U3.2` — Parent Segmentation

##### `T.U3.2.1` — Segment Parents

**Sub-Tasks:**

- `ST.U3.2.1.1` Group parents by payment behavior
- `ST.U3.2.1.2` Identify risk clusters

**Suggested DB Tables for `U3` — Fee Default Prediction:**

- `fee_default_prediction_master`
- `fee_default_prediction_transactions`
- `fee_default_prediction_logs`

**Key API Endpoints for `U3`:**

```
GET    /api/v1/default-prediction-model           # List / index
POST   /api/v1/default-prediction-model           # Create
GET    /api/v1/default-prediction-model/{id}    # Show
PUT    /api/v1/default-prediction-model/{id}    # Update
DELETE /api/v1/default-prediction-model/{id}    # Delete
GET    /api/v1/parent-segmentation           # List / index
POST   /api/v1/parent-segmentation           # Create
GET    /api/v1/parent-segmentation/{id}    # Show
PUT    /api/v1/parent-segmentation/{id}    # Update
DELETE /api/v1/parent-segmentation/{id}    # Delete
```

### U4: Skill Gap Analysis

**Status:** ⬜ Not Started

#### `F.U4.1` — Competency Models

##### `T.U4.1.1` — Analyze Skill Gaps

**Sub-Tasks:**

- `ST.U4.1.1.1` Compare skills vs course outcomes
- `ST.U4.1.1.2` Identify competencies needing improvement

##### `T.U4.1.2` — Generate Personalized Actions

**Sub-Tasks:**

- `ST.U4.1.2.1` Recommend additional content
- `ST.U4.1.2.2` Suggest remedial classes

#### `F.U4.2` — Skill Analytics

##### `T.U4.2.1` — Skill Growth Reports

**Sub-Tasks:**

- `ST.U4.2.1.1` Track skill progression
- `ST.U4.2.1.2` Generate performance dashboards
- `ST.U4.3.1.1` Identify weakest skills per class/section for targeted intervention
- `ST.U4.3.1.2` Compare skill proficiency across different batches or years

**Suggested DB Tables for `U4` — Skill Gap Analysis:**

- `skills`
- `skill_categories`
- `learner_skills`
- `skill_assessments`

**Key API Endpoints for `U4`:**

```
GET    /api/v1/competency-models           # List / index
POST   /api/v1/competency-models           # Create
GET    /api/v1/competency-models/{id}    # Show
PUT    /api/v1/competency-models/{id}    # Update
DELETE /api/v1/competency-models/{id}    # Delete
GET    /api/v1/skill-analytics           # List / index
POST   /api/v1/skill-analytics           # Create
GET    /api/v1/skill-analytics/{id}    # Show
PUT    /api/v1/skill-analytics/{id}    # Update
DELETE /api/v1/skill-analytics/{id}    # Delete
```

### U5: Transport Route Optimization

**Status:** ⬜ Not Started

#### `F.U5.1` — Route Optimization Model

##### `T.U5.1.1` — Optimize Routes

**Sub-Tasks:**

- `ST.U5.1.1.1` Analyze GPS, traffic & stop data
- `ST.U5.1.1.2` Suggest shortest-time routes

##### `T.U5.1.2` — Fuel Efficiency Analytics

**Sub-Tasks:**

- `ST.U5.1.2.1` Detect inefficient routes
- `ST.U5.1.2.2` Predict fuel cost savings

#### `F.U5.2` — Simulation Engine

##### `T.U5.2.1` — Run Simulations

**Sub-Tasks:**

- `ST.U5.2.1.1` Test alternate route plans
- `ST.U5.2.1.2` Generate comparison reports

**Suggested DB Tables for `U5` — Transport Route Optimization:**

- `transport_routes`
- `route_stops`
- `vehicles`
- `drivers`
- `student_transports`

**Key API Endpoints for `U5`:**

```
GET    /api/v1/route-optimization-model           # List / index
POST   /api/v1/route-optimization-model           # Create
GET    /api/v1/route-optimization-model/{id}    # Show
PUT    /api/v1/route-optimization-model/{id}    # Update
DELETE /api/v1/route-optimization-model/{id}    # Delete
GET    /api/v1/simulation-engine           # List / index
POST   /api/v1/simulation-engine           # Create
GET    /api/v1/simulation-engine/{id}    # Show
PUT    /api/v1/simulation-engine/{id}    # Update
DELETE /api/v1/simulation-engine/{id}    # Delete
```

### U6: Resource Allocation Optimization

**Status:** ⬜ Not Started

#### `F.U6.1` — Teacher Allocation

##### `T.U6.1.1` — Optimize Workload

**Sub-Tasks:**

- `ST.U6.1.1.1` Recommend optimal teacher distribution
- `ST.U6.1.1.2` Balance teaching hours

#### `F.U6.2` — Room Allocation

##### `T.U6.2.1` — Suggest Room Assignments

**Sub-Tasks:**

- `ST.U6.2.1.1` Match room size to class strength
- `ST.U6.2.1.2` Avoid laboratory/resource conflicts

**Suggested DB Tables for `U6` — Resource Allocation Optimization:**

- `rooms`
- `room_constraints`
- `lab_resources`

**Key API Endpoints for `U6`:**

```
GET    /api/v1/teacher-allocation           # List / index
POST   /api/v1/teacher-allocation           # Create
GET    /api/v1/teacher-allocation/{id}    # Show
PUT    /api/v1/teacher-allocation/{id}    # Update
DELETE /api/v1/teacher-allocation/{id}    # Delete
GET    /api/v1/room-allocation           # List / index
POST   /api/v1/room-allocation           # Create
GET    /api/v1/room-allocation/{id}    # Show
PUT    /api/v1/room-allocation/{id}    # Update
DELETE /api/v1/room-allocation/{id}    # Delete
```

### U7: AI Dashboards & Visualization

**Status:** ⬜ Not Started

#### `F.U7.1` — AI Dashboards

##### `T.U7.1.1` — Generate Dashboards

**Sub-Tasks:**

- `ST.U7.1.1.1` Display ML predictions
- `ST.U7.1.1.2` Show insights by module

#### `F.U7.2` — What-If Analysis

##### `T.U7.2.1` — Scenario Modeling

**Sub-Tasks:**

- `ST.U7.2.1.1` Simulate academic/attendance changes
- `ST.U7.2.1.2` Predict outcome impact

#### `F.U7.3` — Self-Service Analytics

##### `T.U7.3.1` — Custom Report Builder

**Sub-Tasks:**

- `ST.U7.3.1.1` Provide drag-and-drop interface with data fields from all modules
- `ST.U7.3.1.2` Allow saving and sharing of custom report templates

**Suggested DB Tables for `U7` — AI Dashboards & Visualization:**

- `ai_dashboards_visualization_master`
- `ai_dashboards_visualization_transactions`
- `ai_dashboards_visualization_logs`

**Key API Endpoints for `U7`:**

```
GET    /api/v1/ai-dashboards           # List / index
POST   /api/v1/ai-dashboards           # Create
GET    /api/v1/ai-dashboards/{id}    # Show
PUT    /api/v1/ai-dashboards/{id}    # Update
DELETE /api/v1/ai-dashboards/{id}    # Delete
GET    /api/v1/what-if-analysis           # List / index
POST   /api/v1/what-if-analysis           # Create
GET    /api/v1/what-if-analysis/{id}    # Show
PUT    /api/v1/what-if-analysis/{id}    # Update
DELETE /api/v1/what-if-analysis/{id}    # Delete
GET    /api/v1/self-service-analytics           # List / index
POST   /api/v1/self-service-analytics           # Create
GET    /api/v1/self-service-analytics/{id}    # Show
PUT    /api/v1/self-service-analytics/{id}    # Update
DELETE /api/v1/self-service-analytics/{id}    # Delete
```

### U8: Sentiment & Feedback Analysis

**Status:** ⬜ Not Started

#### `F.U8.1` — NLP Processing

##### `T.U8.1.1` — Analyze Open-Ended Feedback

**Sub-Tasks:**

- `ST.U8.1.1.1` Process survey comments, complaint descriptions, forum posts
- `ST.U8.1.1.2` Categorize sentiment (Positive, Neutral, Negative) and identify key themes

#### `F.U8.2` — Trends & Alerts

##### `T.U8.2.1` — Monitor Sentiment Trends

**Sub-Tasks:**

- `ST.U8.2.1.1` Track sentiment changes over time for specific topics (e.g., teaching quality, facilities)
- `ST.U8.2.1.2` Trigger alerts for sudden negative sentiment spikes

**Suggested DB Tables for `U8` — Sentiment & Feedback Analysis:**

- `sentiment_feedback_analysis_master`
- `sentiment_feedback_analysis_transactions`
- `sentiment_feedback_analysis_logs`

**Key API Endpoints for `U8`:**

```
GET    /api/v1/nlp-processing           # List / index
POST   /api/v1/nlp-processing           # Create
GET    /api/v1/nlp-processing/{id}    # Show
PUT    /api/v1/nlp-processing/{id}    # Update
DELETE /api/v1/nlp-processing/{id}    # Delete
GET    /api/v1/trends---alerts           # List / index
POST   /api/v1/trends---alerts           # Create
GET    /api/v1/trends---alerts/{id}    # Show
PUT    /api/v1/trends---alerts/{id}    # Update
DELETE /api/v1/trends---alerts/{id}    # Delete
```

### U9: Institutional Benchmarking

**Status:** ⬜ Not Started

#### `F.U9.1` — KPI Definition & Comparison

##### `T.U9.1.1` — Define Institutional KPIs

**Sub-Tasks:**

- `ST.U9.1.1.1` Select metrics (Pass %, Avg. Attendance, Fee Collection Ratio, Teacher Retention)
- `ST.U9.1.1.2` Set target values and weighting for each KPI

##### `T.U9.1.2` — Benchmark Analysis

**Sub-Tasks:**

- `ST.U9.1.2.1` Compare school performance against anonymized peer group data
- `ST.U9.1.2.2` Generate gap analysis report with improvement recommendations

**Suggested DB Tables for `U9` — Institutional Benchmarking:**

- `institutional_benchmarking_master`
- `institutional_benchmarking_transactions`
- `institutional_benchmarking_logs`

**Key API Endpoints for `U9`:**

```
GET    /api/v1/kpi-definition---comparison           # List / index
POST   /api/v1/kpi-definition---comparison           # Create
GET    /api/v1/kpi-definition---comparison/{id}    # Show
PUT    /api/v1/kpi-definition---comparison/{id}    # Update
DELETE /api/v1/kpi-definition---comparison/{id}    # Delete
```

### Screen Design Requirements — Module U


### Report Requirements — Module U

- **Skill Analytics**: Tabular report with date range filter, export to PDF/Excel/CSV
- **Institutional Skill Analytics**: Tabular report with date range filter, export to PDF/Excel/CSV
- **Self-Service Analytics**: Tabular report with date range filter, export to PDF/Excel/CSV

### Test Case Requirements — Module U

| Test Type | Scope |
|---|---|
| **Unit Tests** | All service classes and model methods in Module U |
| **Feature Tests** | All API endpoints — happy path, validation errors, auth failures |
| **Browser Tests** | Form submissions, list pagination, filter/search, export |
| **Functional Tests** | End-to-end business workflows (e.g., create → approve → complete lifecycle) |

---

## Module V: Multi-Tenant Billing & SaaS

| | |
|---|---|
| **Module Code** | `V` |
| **App Type** | Prime |
| **Description** | Subscription plans, tenant billing, payment gateways, usage metering, compliance audit. |
| **Total Sub-Modules** | 7 |
| **Total Features (Tasks)** | 25 |
| **Total Sub-Tasks** | 54 |

### Sub-Module Status

| Sub-Mod Code | Sub-Module Name | App Type | Status |
|---|---|---|---|
| `V1` | Subscription Plans & Pricing | Both | ✅ Completed 100% |
| `V2` | Tenant Subscription Assignment | Both | ✅ Completed 100% |
| `V3` | Billing Engine | Both | ✅ Completed 100% |
| `V4` | Metering, Usage & Overage Tracking | Both | ✅ Completed 100% |
| `V5` | Payment Gateways & Integrations | Both | ✅ Completed  |
| `V6` | Tenant Billing Portal | Both | ✅ Completed 100% |
| `V7` | SaaS Compliance & Audit | Both | ✅ Completed 100% |

### V1: Subscription Plans & Pricing

**Status:** ✅ Completed 100%

#### `F.V1.1` — Plan Configuration

##### `T.V1.1.1` — Create Subscription Plan

**Sub-Tasks:**

- `ST.V1.1.1.1` Define plan name & description
- `ST.V1.1.1.2` Set pricing (monthly/quarterly/yearly)
- `ST.V1.1.1.3` Assign included modules/features

##### `T.V1.1.2` — Plan Rules

**Sub-Tasks:**

- `ST.V1.1.2.1` Define user limits
- `ST.V1.1.2.2` Set storage limits
- `ST.V1.1.2.3` Configure overage pricing

#### `F.V1.2` — Plan Management

##### `T.V1.2.1` — Edit/Update Plan

**Sub-Tasks:**

- `ST.V1.2.1.1` Modify pricing & limits
- `ST.V1.2.1.2` Update feature list

##### `T.V1.2.2` — Plan Activation/Deactivation

**Sub-Tasks:**

- `ST.V1.2.2.1` Activate plan for sale
- `ST.V1.2.2.2` Retire old plan versions

**Suggested DB Tables for `V1` — Subscription Plans & Pricing:**

- `subscription_plans`
- `tenant_subscriptions`
- `invoices`
- `payments`

**Key API Endpoints for `V1`:**

```
GET    /api/v1/plan-configuration           # List / index
POST   /api/v1/plan-configuration           # Create
GET    /api/v1/plan-configuration/{id}    # Show
PUT    /api/v1/plan-configuration/{id}    # Update
DELETE /api/v1/plan-configuration/{id}    # Delete
GET    /api/v1/plan-management           # List / index
POST   /api/v1/plan-management           # Create
GET    /api/v1/plan-management/{id}    # Show
PUT    /api/v1/plan-management/{id}    # Update
DELETE /api/v1/plan-management/{id}    # Delete
```

### V2: Tenant Subscription Assignment

**Status:** ✅ Completed 100%

#### `F.V2.1` — Subscription Purchase

##### `T.V2.1.1` — Assign Plan to Tenant

**Sub-Tasks:**

- `ST.V2.1.1.1` Select subscription plan
- `ST.V2.1.1.2` Set start/end date
- `ST.V2.1.1.3` Configure billing cycle

##### `T.V2.1.2` — Trial Management

**Sub-Tasks:**

- `ST.V2.1.2.1` Enable trial period
- `ST.V2.1.2.2` Auto‑convert trial to paid subscription

#### `F.V2.2` — Subscription Lifecycle

##### `T.V2.2.1` — Renewal Management

**Sub-Tasks:**

- `ST.V2.2.1.1` Auto‑renew subscription
- `ST.V2.2.1.2` Notify tenant for manual renewal

##### `T.V2.2.2` — Upgrade/Downgrade

**Sub-Tasks:**

- `ST.V2.2.2.1` Switch plan mid‑cycle
- `ST.V2.2.2.2` Apply prorated charges

**Suggested DB Tables for `V2` — Tenant Subscription Assignment:**

- `subscription_plans`
- `tenant_subscriptions`
- `invoices`
- `payments`

**Key API Endpoints for `V2`:**

```
GET    /api/v1/subscription-purchase           # List / index
POST   /api/v1/subscription-purchase           # Create
GET    /api/v1/subscription-purchase/{id}    # Show
PUT    /api/v1/subscription-purchase/{id}    # Update
DELETE /api/v1/subscription-purchase/{id}    # Delete
GET    /api/v1/subscription-lifecycle           # List / index
POST   /api/v1/subscription-lifecycle           # Create
GET    /api/v1/subscription-lifecycle/{id}    # Show
PUT    /api/v1/subscription-lifecycle/{id}    # Update
DELETE /api/v1/subscription-lifecycle/{id}    # Delete
```

### V3: Billing Engine

**Status:** ✅ Completed 100%

#### `F.V3.1` — Invoice Generation

##### `T.V3.1.1` — Generate Invoice

**Sub-Tasks:**

- `ST.V3.1.1.1` Create recurring invoice
- `ST.V3.1.1.2` Include addons/overage usage
- `ST.V3.1.1.3` Apply taxes as per region

##### `T.V3.1.2` — Invoice Scheduling

**Sub-Tasks:**

- `ST.V3.1.2.1` Schedule monthly/annual billing
- `ST.V3.1.2.2` Send reminders for unpaid invoices

#### `F.V3.2` — Payment Processing

##### `T.V3.2.1` — Record Payment

**Sub-Tasks:**

- `ST.V3.2.1.1` Accept online payment (UPI/Card)
- `ST.V3.2.1.2` Record offline payment (NEFT/Cash)

##### `T.V3.2.2` — Auto‑Reconciliation

**Sub-Tasks:**

- `ST.V3.2.2.1` Match payment with invoice automatically
- `ST.V3.2.2.2` Flag mismatched transactions

**Suggested DB Tables for `V3` — Billing Engine:**

- `subscription_plans`
- `tenant_subscriptions`
- `invoices`
- `payments`

**Key API Endpoints for `V3`:**

```
GET    /api/v1/invoice-generation           # List / index
POST   /api/v1/invoice-generation           # Create
GET    /api/v1/invoice-generation/{id}    # Show
PUT    /api/v1/invoice-generation/{id}    # Update
DELETE /api/v1/invoice-generation/{id}    # Delete
GET    /api/v1/payment-processing           # List / index
POST   /api/v1/payment-processing           # Create
GET    /api/v1/payment-processing/{id}    # Show
PUT    /api/v1/payment-processing/{id}    # Update
DELETE /api/v1/payment-processing/{id}    # Delete
```

### V4: Metering, Usage & Overage Tracking

**Status:** ✅ Completed 100%

#### `F.V4.1` — Usage Monitoring

##### `T.V4.1.1` — Track Resource Usage

**Sub-Tasks:**

- `ST.V4.1.1.1` Monitor API calls
- `ST.V4.1.1.2` Track storage consumption

##### `T.V4.1.2` — Overage Alerts

**Sub-Tasks:**

- `ST.V4.1.2.1` Notify tenant when nearing limits
- `ST.V4.1.2.2` Auto‑lock premium features when exceeded

#### `F.V4.2` — Overage Billing

##### `T.V4.2.1` — Calculate Overage Charges

**Sub-Tasks:**

- `ST.V4.2.1.1` Multiply usage above threshold
- `ST.V4.2.1.2` Apply overage invoice line items

**Suggested DB Tables for `V4` — Metering, Usage & Overage Tracking:**

- `metering,_usage_overage_tracki_master`
- `metering,_usage_overage_tracki_transactions`
- `metering,_usage_overage_tracki_logs`

**Key API Endpoints for `V4`:**

```
GET    /api/v1/usage-monitoring           # List / index
POST   /api/v1/usage-monitoring           # Create
GET    /api/v1/usage-monitoring/{id}    # Show
PUT    /api/v1/usage-monitoring/{id}    # Update
DELETE /api/v1/usage-monitoring/{id}    # Delete
GET    /api/v1/overage-billing           # List / index
POST   /api/v1/overage-billing           # Create
GET    /api/v1/overage-billing/{id}    # Show
PUT    /api/v1/overage-billing/{id}    # Update
DELETE /api/v1/overage-billing/{id}    # Delete
```

### V5: Payment Gateways & Integrations

**Status:** ✅ Completed 

#### `F.V5.1` — Gateway Setup

##### `T.V5.1.1` — Configure Gateway

**Sub-Tasks:**

- `ST.V5.1.1.1` Add API keys for Razorpay/Stripe/PayPal
- `ST.V5.1.1.2` Set webhook URL for payment confirmation

##### `T.V5.1.2` — Gateway Testing

**Sub-Tasks:**

- `ST.V5.1.2.1` Send test payment request
- `ST.V5.1.2.2` Verify webhook response

#### `F.V5.2` — Multi‑Currency Support

##### `T.V5.2.1` — Enable Currencies

**Sub-Tasks:**

- `ST.V5.2.1.1` Configure supported currencies
- `ST.V5.2.1.2` Set exchange rate source

**Suggested DB Tables for `V5` — Payment Gateways & Integrations:**

- `payment_gateways_integrations_master`
- `payment_gateways_integrations_transactions`
- `payment_gateways_integrations_logs`

**Key API Endpoints for `V5`:**

```
GET    /api/v1/gateway-setup           # List / index
POST   /api/v1/gateway-setup           # Create
GET    /api/v1/gateway-setup/{id}    # Show
PUT    /api/v1/gateway-setup/{id}    # Update
DELETE /api/v1/gateway-setup/{id}    # Delete
GET    /api/v1/multi‑currency-support           # List / index
POST   /api/v1/multi‑currency-support           # Create
GET    /api/v1/multi‑currency-support/{id}    # Show
PUT    /api/v1/multi‑currency-support/{id}    # Update
DELETE /api/v1/multi‑currency-support/{id}    # Delete
```

### V6: Tenant Billing Portal

**Status:** ✅ Completed 100%

#### `F.V6.1` — Billing Dashboard

##### `T.V6.1.1` — View Billing History

**Sub-Tasks:**

- `ST.V6.1.1.1` Display invoices list
- `ST.V6.1.1.2` Filter by paid/unpaid

##### `T.V6.1.2` — View Usage Summary

**Sub-Tasks:**

- `ST.V6.1.2.1` Show API/storage usage
- `ST.V6.1.2.2` Highlight overage areas

#### `F.V6.2` — Self‑Service Payments

##### `T.V6.2.1` — Download Invoice

**Sub-Tasks:**

- `ST.V6.2.1.1` Download invoice PDF
- `ST.V6.2.1.2` Download payment receipt

##### `T.V6.2.2` — Make Online Payment

**Sub-Tasks:**

- `ST.V6.2.2.1` Redirect to online payment gateway
- `ST.V6.2.2.2` Update payment status in system

**Suggested DB Tables for `V6` — Tenant Billing Portal:**

- `subscription_plans`
- `tenant_subscriptions`
- `invoices`
- `payments`

**Key API Endpoints for `V6`:**

```
GET    /api/v1/billing-dashboard           # List / index
POST   /api/v1/billing-dashboard           # Create
GET    /api/v1/billing-dashboard/{id}    # Show
PUT    /api/v1/billing-dashboard/{id}    # Update
DELETE /api/v1/billing-dashboard/{id}    # Delete
GET    /api/v1/self‑service-payments           # List / index
POST   /api/v1/self‑service-payments           # Create
GET    /api/v1/self‑service-payments/{id}    # Show
PUT    /api/v1/self‑service-payments/{id}    # Update
DELETE /api/v1/self‑service-payments/{id}    # Delete
```

### V7: SaaS Compliance & Audit

**Status:** ✅ Completed 100%

#### `F.V7.1` — Audit Logs

##### `T.V7.1.1` — Track Billing Events

**Sub-Tasks:**

- `ST.V7.1.1.1` Record invoice creation
- `ST.V7.1.1.2` Log payment confirmations

##### `T.V7.1.2` — Track Subscription Updates

**Sub-Tasks:**

- `ST.V7.1.2.1` Record plan upgrade/downgrade
- `ST.V7.1.2.2` Maintain full audit trail

#### `F.V7.2` — Compliance Reports

##### `T.V7.2.1` — Generate Compliance Report

**Sub-Tasks:**

- `ST.V7.2.1.1` GST/Tax reports
- `ST.V7.2.1.2` Country‑wise billing summaries

**Suggested DB Tables for `V7` — SaaS Compliance & Audit:**

- `audit_logs`
- `system_events`

**Key API Endpoints for `V7`:**

```
GET    /api/v1/audit-logs           # List / index
POST   /api/v1/audit-logs           # Create
GET    /api/v1/audit-logs/{id}    # Show
PUT    /api/v1/audit-logs/{id}    # Update
DELETE /api/v1/audit-logs/{id}    # Delete
GET    /api/v1/compliance-reports           # List / index
POST   /api/v1/compliance-reports           # Create
GET    /api/v1/compliance-reports/{id}    # Show
PUT    /api/v1/compliance-reports/{id}    # Update
DELETE /api/v1/compliance-reports/{id}    # Delete
```

### Screen Design Requirements — Module V


### Report Requirements — Module V

- **Audit Logs**: Tabular report with date range filter, export to PDF/Excel/CSV
- **Compliance Reports**: Tabular report with date range filter, export to PDF/Excel/CSV

### Test Case Requirements — Module V

| Test Type | Scope |
|---|---|
| **Unit Tests** | All service classes and model methods in Module V |
| **Feature Tests** | All API endpoints — happy path, validation errors, auth failures |
| **Browser Tests** | Form submissions, list pagination, filter/search, export |
| **Functional Tests** | End-to-end business workflows (e.g., create → approve → complete lifecycle) |

---

## Module W: Cafeteria & Mess Management

| | |
|---|---|
| **Module Code** | `W` |
| **App Type** | Both |
| **Description** | Digital menu, online meal ordering, kitchen stock management. |
| **Total Sub-Modules** | 3 |
| **Total Features (Tasks)** | 6 |
| **Total Sub-Tasks** | 12 |

### Sub-Module Status

| Sub-Mod Code | Sub-Module Name | App Type | Status |
|---|---|---|---|
| `W1` | Digital Menu Management | Both | ⬜ Not Started |
| `W2` | Online Ordering & Pre-Booking | Both | ⬜ Not Started |
| `W3` | Inventory & Kitchen Stock | Both | ⬜ Not Started |

### W1: Digital Menu Management

**Status:** ⬜ Not Started

#### `F.W1.1` — Weekly Menu Planner

##### `T.W1.1.1` — Create Meal Plan

**Sub-Tasks:**

- `ST.W1.1.1.1` Add dishes with detailed descriptions, nutritional info, and allergen warnings
- `ST.W1.1.1.2` Assign meal plan to specific days and meal types (Breakfast, Lunch, Snacks)

##### `T.W1.1.2` — Publish & Notify

**Sub-Tasks:**

- `ST.W1.1.2.1` Publish weekly menu to parent/student portal
- `ST.W1.1.2.2` Send push notification/SMS alert for menu updates

**Suggested DB Tables for `W1` — Digital Menu Management:**

- `meal_menus`
- `meal_orders`
- `kitchen_stock`

**Key API Endpoints for `W1`:**

```
GET    /api/v1/weekly-menu-planner           # List / index
POST   /api/v1/weekly-menu-planner           # Create
GET    /api/v1/weekly-menu-planner/{id}    # Show
PUT    /api/v1/weekly-menu-planner/{id}    # Update
DELETE /api/v1/weekly-menu-planner/{id}    # Delete
```

### W2: Online Ordering & Pre-Booking

**Status:** ⬜ Not Started

#### `F.W2.1` — Meal Pre-Ordering

##### `T.W2.1.1` — Student/Parent Order Interface

**Sub-Tasks:**

- `ST.W2.1.1.1` Browse weekly menu and select meals for upcoming days
- `ST.W2.1.1.2` Specify special dietary requirements (e.g., Jain, No onion-garlic)

##### `T.W2.1.2` — Order Management

**Sub-Tasks:**

- `ST.W2.1.2.1` View consolidated order list for kitchen preparation
- `ST.W2.1.2.2` Close ordering window before meal time (e.g., 2 hours before lunch)

**Suggested DB Tables for `W2` — Online Ordering & Pre-Booking:**

- `books`
- `book_copies`
- `library_members`
- `book_issues`

**Key API Endpoints for `W2`:**

```
GET    /api/v1/meal-pre-ordering           # List / index
POST   /api/v1/meal-pre-ordering           # Create
GET    /api/v1/meal-pre-ordering/{id}    # Show
PUT    /api/v1/meal-pre-ordering/{id}    # Update
DELETE /api/v1/meal-pre-ordering/{id}    # Delete
```

### W3: Inventory & Kitchen Stock

**Status:** ⬜ Not Started

#### `F.W3.1` — Stock Management

##### `T.W3.1.1` — Manage Raw Materials

**Sub-Tasks:**

- `ST.W3.1.1.1` Record inventory of grains, pulses, vegetables, spices
- `ST.W3.1.1.2` Set reorder levels and generate purchase requests automatically

##### `T.W3.1.2` — Consumption Tracking

**Sub-Tasks:**

- `ST.W3.1.2.1` Log actual consumption against planned meals
- `ST.W3.1.2.2` Calculate food cost and wastage reports

**Suggested DB Tables for `W3` — Inventory & Kitchen Stock:**

- `item_categories`
- `items`
- `item_units`
- `stock_ledger`

**Key API Endpoints for `W3`:**

```
GET    /api/v1/stock-management           # List / index
POST   /api/v1/stock-management           # Create
GET    /api/v1/stock-management/{id}    # Show
PUT    /api/v1/stock-management/{id}    # Update
DELETE /api/v1/stock-management/{id}    # Delete
```

### Screen Design Requirements — Module W


### Report Requirements — Module W

- Module-level summary report with filters and export

### Test Case Requirements — Module W

| Test Type | Scope |
|---|---|
| **Unit Tests** | All service classes and model methods in Module W |
| **Feature Tests** | All API endpoints — happy path, validation errors, auth failures |
| **Browser Tests** | Form submissions, list pagination, filter/search, export |
| **Functional Tests** | End-to-end business workflows (e.g., create → approve → complete lifecycle) |

---

## Module X: Visitor & Security Management

| | |
|---|---|
| **Module Code** | `X` |
| **App Type** | Both |
| **Description** | Digital visitor registration, gate security, campus security alerts. |
| **Total Sub-Modules** | 3 |
| **Total Features (Tasks)** | 6 |
| **Total Sub-Tasks** | 12 |

### Sub-Module Status

| Sub-Mod Code | Sub-Module Name | App Type | Status |
|---|---|---|---|
| `X1` | Digital Visitor Registration | Both | ⬜ Not Started |
| `X2` | Gate Security Integration | Both | ⬜ Not Started |
| `X3` | Security Alerts & Monitoring | Both | ⬜ Not Started |

### X1: Digital Visitor Registration

**Status:** ⬜ Not Started

#### `F.X1.1` — Pre-Registration

##### `T.X1.1.1` — Visitor Pre-Registration

**Sub-Tasks:**

- `ST.X1.1.1.1` Allow hosts to pre-register visitors with details (name, phone, purpose, vehicle)
- `ST.X1.1.1.2` Send pre-registration QR code to visitor via SMS/Email

##### `T.X1.1.2` — Walking Registration

**Sub-Tasks:**

- `ST.X1.1.2.1` Register walk-in visitors at reception/kiosk
- `ST.X1.1.2.2` Capture visitor photo and ID proof scan

**Suggested DB Tables for `X1` — Digital Visitor Registration:**

- `visitors`
- `visitor_passes`
- `gate_logs`

**Key API Endpoints for `X1`:**

```
GET    /api/v1/pre-registration           # List / index
POST   /api/v1/pre-registration           # Create
GET    /api/v1/pre-registration/{id}    # Show
PUT    /api/v1/pre-registration/{id}    # Update
DELETE /api/v1/pre-registration/{id}    # Delete
```

### X2: Gate Security Integration

**Status:** ⬜ Not Started

#### `F.X2.1` — Check-in/Check-out

##### `T.X2.1.1` — Process Visitor Entry

**Sub-Tasks:**

- `ST.X2.1.1.1` Security scans QR code (pre-reg or on-site) at gate
- `ST.X2.1.1.2` System records check-in time, captures live photo, prints temporary badge

##### `T.X2.1.2` — Visitor Exit

**Sub-Tasks:**

- `ST.X2.1.2.1` Scan badge/QR code at exit to record check-out time
- `ST.X2.1.2.2` Flag overdue visitors (still inside beyond expected duration)

**Suggested DB Tables for `X2` — Gate Security Integration:**

- `gate_security_integration_master`
- `gate_security_integration_transactions`
- `gate_security_integration_logs`

**Key API Endpoints for `X2`:**

```
GET    /api/v1/check-in-check-out           # List / index
POST   /api/v1/check-in-check-out           # Create
GET    /api/v1/check-in-check-out/{id}    # Show
PUT    /api/v1/check-in-check-out/{id}    # Update
DELETE /api/v1/check-in-check-out/{id}    # Delete
```

### X3: Security Alerts & Monitoring

**Status:** ⬜ Not Started

#### `F.X3.1` — Real-time Dashboard

##### `T.X3.1.1` — Monitor Campus Activity

**Sub-Tasks:**

- `ST.X3.1.1.1` Display live count of visitors on campus, current check-ins
- `ST.X3.1.1.2` Show list of visitors with expired time or in restricted zones

#### `F.X3.2` — Emergency Alerts

##### `T.X3.2.1` — Broadcast Emergency

**Sub-Tasks:**

- `ST.X3.2.1.1` Send instant SMS/App alert to all staff for lockdown, evacuation
- `ST.X3.2.1.2` Initiate automated roll call or headcount procedure via system

**Suggested DB Tables for `X3` — Security Alerts & Monitoring:**

- `audit_logs`
- `system_events`

**Key API Endpoints for `X3`:**

```
GET    /api/v1/real-time-dashboard           # List / index
POST   /api/v1/real-time-dashboard           # Create
GET    /api/v1/real-time-dashboard/{id}    # Show
PUT    /api/v1/real-time-dashboard/{id}    # Update
DELETE /api/v1/real-time-dashboard/{id}    # Delete
GET    /api/v1/emergency-alerts           # List / index
POST   /api/v1/emergency-alerts           # Create
GET    /api/v1/emergency-alerts/{id}    # Show
PUT    /api/v1/emergency-alerts/{id}    # Update
DELETE /api/v1/emergency-alerts/{id}    # Delete
```

### Screen Design Requirements — Module X


### Report Requirements — Module X

- Module-level summary report with filters and export

### Test Case Requirements — Module X

| Test Type | Scope |
|---|---|
| **Unit Tests** | All service classes and model methods in Module X |
| **Feature Tests** | All API endpoints — happy path, validation errors, auth failures |
| **Browser Tests** | Form submissions, list pagination, filter/search, export |
| **Functional Tests** | End-to-end business workflows (e.g., create → approve → complete lifecycle) |

---

## Module Y: Maintenance & Facility Helpdesk

| | |
|---|---|
| **Module Code** | `Y` |
| **App Type** | Both |
| **Description** | Ticketing system for maintenance issues, preventive maintenance scheduling. |
| **Total Sub-Modules** | 2 |
| **Total Features (Tasks)** | 6 |
| **Total Sub-Tasks** | 12 |

### Sub-Module Status

| Sub-Mod Code | Sub-Module Name | App Type | Status |
|---|---|---|---|
| `Y1` | Ticketing System | Both | ⬜ Not Started |
| `Y2` | Preventive Maintenance | Both | ⬜ Not Started |

### Y1: Ticketing System

**Status:** ⬜ Not Started

#### `F.Y1.1` — Issue Reporting

##### `T.Y1.1.1` — Create Maintenance Ticket

**Sub-Tasks:**

- `ST.Y1.1.1.1` Staff/Student selects category (Electrical, Plumbing, Carpenter, IT, Cleaning)
- `ST.Y1.1.1.2` Provide detailed description, location (Room/Building), and upload photos

##### `T.Y1.1.2` — Ticket Prioritization

**Sub-Tasks:**

- `ST.Y1.1.2.1` Auto-assign priority based on category and keywords (e.g., "water leakage" = High)
- `ST.Y1.1.2.2` Allow manual override of priority by admin

#### `F.Y1.2` — Work Assignment & Tracking

##### `T.Y1.2.1` — Assign to Technician

**Sub-Tasks:**

- `ST.Y1.2.1.1` Auto-assign ticket to available technician based on skill and location
- `ST.Y1.2.1.2` Send assignment notification to technician's mobile app

##### `T.Y1.2.2` — Track Progress

**Sub-Tasks:**

- `ST.Y1.2.2.1` Technician updates status (Accepted, In Progress, On Hold, Resolved)
- `ST.Y1.2.2.2` Log time spent, parts used, and resolution notes with before-after photos

**Suggested DB Tables for `Y1` — Ticketing System:**

- `maintenance_tickets`
- `ticket_assignments`
- `pm_schedules`

**Key API Endpoints for `Y1`:**

```
GET    /api/v1/issue-reporting           # List / index
POST   /api/v1/issue-reporting           # Create
GET    /api/v1/issue-reporting/{id}    # Show
PUT    /api/v1/issue-reporting/{id}    # Update
DELETE /api/v1/issue-reporting/{id}    # Delete
GET    /api/v1/work-assignment---tracking           # List / index
POST   /api/v1/work-assignment---tracking           # Create
GET    /api/v1/work-assignment---tracking/{id}    # Show
PUT    /api/v1/work-assignment---tracking/{id}    # Update
DELETE /api/v1/work-assignment---tracking/{id}    # Delete
```

### Y2: Preventive Maintenance

**Status:** ⬜ Not Started

#### `F.Y2.1` — Schedule PM Tasks

##### `T.Y2.1.1` — Define PM Checklist

**Sub-Tasks:**

- `ST.Y2.1.1.1` Create checklist for assets (Generator service, Fire extinguisher check)
- `ST.Y2.1.1.2` Set recurrence (Weekly, Monthly, Quarterly, Yearly)

##### `T.Y2.1.2` — Generate PM Work Orders

**Sub-Tasks:**

- `ST.Y2.1.2.1` System auto-generates work orders based on schedule
- `ST.Y2.1.2.2` Assign work orders and track completion to maintain asset health

**Suggested DB Tables for `Y2` — Preventive Maintenance:**

- `maintenance_tickets`
- `ticket_assignments`
- `pm_schedules`

**Key API Endpoints for `Y2`:**

```
GET    /api/v1/schedule-pm-tasks           # List / index
POST   /api/v1/schedule-pm-tasks           # Create
GET    /api/v1/schedule-pm-tasks/{id}    # Show
PUT    /api/v1/schedule-pm-tasks/{id}    # Update
DELETE /api/v1/schedule-pm-tasks/{id}    # Delete
```

### Screen Design Requirements — Module Y


### Report Requirements — Module Y

- **Issue Reporting**: Tabular report with date range filter, export to PDF/Excel/CSV

### Test Case Requirements — Module Y

| Test Type | Scope |
|---|---|
| **Unit Tests** | All service classes and model methods in Module Y |
| **Feature Tests** | All API endpoints — happy path, validation errors, auth failures |
| **Browser Tests** | Form submissions, list pagination, filter/search, export |
| **Functional Tests** | End-to-end business workflows (e.g., create → approve → complete lifecycle) |

---

## Module Z: Parent Portal & Mobile App

| | |
|---|---|
| **Module Code** | `Z` |
| **App Type** | Both |
| **Description** | Unified parent dashboard, real-time notifications, teacher messaging, fee payments, document vault. |
| **Total Sub-Modules** | 6 |
| **Total Features (Tasks)** | 12 |
| **Total Sub-Tasks** | 24 |

### Sub-Module Status

| Sub-Mod Code | Sub-Module Name | App Type | Status |
|---|---|---|---|
| `Z1` | Unified Parent Dashboard | Both | ⬜ Not Started |
| `Z2` | Real-Time Notifications | Both | ⬜ Not Started |
| `Z3` | In-App Communication | Both | ⬜ Not Started |
| `Z4` | Fee Management | Both | ⬜ Not Started |
| `Z5` | Event & Volunteer Management | Both | ⬜ Not Started |
| `Z6` | Document Vault & Reports | Both | ⬜ Not Started |

### Z1: Unified Parent Dashboard

**Status:** ⬜ Not Started

#### `F.Z1.1` — Child Overview

##### `T.Z1.1.1` — Display Child Summary

**Sub-Tasks:**

- `ST.Z1.1.1.1` Show all children with photos, classes, sections in single view
- `ST.Z1.1.1.2` Show today's timetable, next class, and current location (if transport enabled)

##### `T.Z1.1.2` — Academic Snapshot

**Sub-Tasks:**

- `ST.Z1.1.2.1` Display recent attendance %, last test scores, pending homework
- `ST.Z1.1.2.2` Show fee dues summary and upcoming payment deadlines

**Suggested DB Tables for `Z1` — Unified Parent Dashboard:**

- `parent_notifications`
- `parent_messages`
- `parent_document_access`

**Key API Endpoints for `Z1`:**

```
GET    /api/v1/child-overview           # List / index
POST   /api/v1/child-overview           # Create
GET    /api/v1/child-overview/{id}    # Show
PUT    /api/v1/child-overview/{id}    # Update
DELETE /api/v1/child-overview/{id}    # Delete
```

### Z2: Real-Time Notifications

**Status:** ⬜ Not Started

#### `F.Z2.1` — Smart Alerts

##### `T.Z2.1.1` — Configure Alert Preferences

**Sub-Tasks:**

- `ST.Z2.1.1.1` Parent chooses notification types (Fee Reminders, Absence Alerts, Exam Results)
- `ST.Z2.1.1.2` Set quiet hours to mute non-urgent notifications

##### `T.Z2.1.2` — Push Notification Delivery

**Sub-Tasks:**

- `ST.Z2.1.2.1` Ensure reliable delivery via FCM (Android) and APNs (iOS)
- `ST.Z2.1.2.2` Handle device token updates and notification preferences per device

**Suggested DB Tables for `Z2` — Real-Time Notifications:**

- `notification_settings`
- `smtp_configs`
- `sms_gateway_configs`

**Key API Endpoints for `Z2`:**

```
GET    /api/v1/smart-alerts           # List / index
POST   /api/v1/smart-alerts           # Create
GET    /api/v1/smart-alerts/{id}    # Show
PUT    /api/v1/smart-alerts/{id}    # Update
DELETE /api/v1/smart-alerts/{id}    # Delete
```

### Z3: In-App Communication

**Status:** ⬜ Not Started

#### `F.Z3.1` — Teacher Messaging

##### `T.Z3.1.1` — Send Message to Teacher

**Sub-Tasks:**

- `ST.Z3.1.1.1` Select teacher from child's subject list and compose message
- `ST.Z3.1.1.2` Attach files (photos, documents) and track read receipts

##### `T.Z3.1.2` — Message History & Search

**Sub-Tasks:**

- `ST.Z3.1.2.1` View complete message history with any teacher
- `ST.Z3.1.2.2` Search messages by keyword, teacher, or date range

**Suggested DB Tables for `Z3` — In-App Communication:**

- `communication_logs`
- `email_templates`
- `sms_templates`
- `notification_logs`

**Key API Endpoints for `Z3`:**

```
GET    /api/v1/teacher-messaging           # List / index
POST   /api/v1/teacher-messaging           # Create
GET    /api/v1/teacher-messaging/{id}    # Show
PUT    /api/v1/teacher-messaging/{id}    # Update
DELETE /api/v1/teacher-messaging/{id}    # Delete
```

### Z4: Fee Management

**Status:** ⬜ Not Started

#### `F.Z4.1` — Online Payments

##### `T.Z4.1.1` — Pay Fee Online

**Sub-Tasks:**

- `ST.Z4.1.1.1` View detailed fee breakdown and select specific installments to pay
- `ST.Z4.1.1.2` Choose payment method (Credit/Debit Card, Net Banking, UPI, Wallet)

##### `T.Z4.1.2` — Payment History & Receipts

**Sub-Tasks:**

- `ST.Z4.1.2.1` View all past transactions with status (Success, Failed, Pending)
- `ST.Z4.1.2.2` Download and share payment receipts as PDF

**Suggested DB Tables for `Z4` — Fee Management:**

- `fee_management_master`
- `fee_management_transactions`
- `fee_management_logs`

**Key API Endpoints for `Z4`:**

```
GET    /api/v1/online-payments           # List / index
POST   /api/v1/online-payments           # Create
GET    /api/v1/online-payments/{id}    # Show
PUT    /api/v1/online-payments/{id}    # Update
DELETE /api/v1/online-payments/{id}    # Delete
```

### Z5: Event & Volunteer Management

**Status:** ⬜ Not Started

#### `F.Z5.1` — Event Participation

##### `T.Z5.1.1` — View School Events

**Sub-Tasks:**

- `ST.Z5.1.1.1` Browse calendar of upcoming events (PTM, Sports Day, Festivals)
- `ST.Z5.1.1.2` RSVP for events and add to personal calendar

##### `T.Z5.1.2` — Volunteer Sign-up

**Sub-Tasks:**

- `ST.Z5.1.2.1` Sign up for volunteer roles for events (e.g., Food stall, decoration)
- `ST.Z5.1.2.2` Receive confirmation and reminders for assigned volunteer duties

**Suggested DB Tables for `Z5` — Event & Volunteer Management:**

- `event_volunteer_management_master`
- `event_volunteer_management_transactions`
- `event_volunteer_management_logs`

**Key API Endpoints for `Z5`:**

```
GET    /api/v1/event-participation           # List / index
POST   /api/v1/event-participation           # Create
GET    /api/v1/event-participation/{id}    # Show
PUT    /api/v1/event-participation/{id}    # Update
DELETE /api/v1/event-participation/{id}    # Delete
```

### Z6: Document Vault & Reports

**Status:** ⬜ Not Started

#### `F.Z6.1` — Secure Document Access

##### `T.Z6.1.1` — Access Child Documents

**Sub-Tasks:**

- `ST.Z6.1.1.1` View and download report cards, mark sheets, certificates
- `ST.Z6.1.1.2` Access medical records, vaccination certificates (with consent)

##### `T.Z6.1.2` — Request Official Copies

**Sub-Tasks:**

- `ST.Z6.1.2.1` Submit online request for duplicate report cards or certificates
- `ST.Z6.1.2.2` Track request status and pay any applicable fees online

**Suggested DB Tables for `Z6` — Document Vault & Reports:**

- `student_documents`
- `document_verifications`

**Key API Endpoints for `Z6`:**

```
GET    /api/v1/secure-document-access           # List / index
POST   /api/v1/secure-document-access           # Create
GET    /api/v1/secure-document-access/{id}    # Show
PUT    /api/v1/secure-document-access/{id}    # Update
DELETE /api/v1/secure-document-access/{id}    # Delete
```

### Screen Design Requirements — Module Z


### Report Requirements — Module Z

- Module-level summary report with filters and export

### Test Case Requirements — Module Z

| Test Type | Scope |
|---|---|
| **Unit Tests** | All service classes and model methods in Module Z |
| **Feature Tests** | All API endpoints — happy path, validation errors, auth failures |
| **Browser Tests** | Form submissions, list pagination, filter/search, export |
| **Functional Tests** | End-to-end business workflows (e.g., create → approve → complete lifecycle) |

---

## 4. Cross-Cutting Technical Requirements

### 4.1 Authentication & Authorization

```php
// Every controller method must pass through:
// 1. Sanctum token authentication
// 2. Tenant isolation middleware (resolves correct DB)
// 3. Role & Permission gate check

// Example policy check:
\$this->authorize('create', Tenant::class);

// Permission naming convention:
// {module_code}.{sub_mod_code}.{action}
// e.g. 'A.A1.create', 'B.B2.edit', 'J.J3.delete'
```

### 4.2 Multi-Tenancy Implementation

```php
// stancl/tenancy package OR custom middleware
// Middleware stack:
// 1. ResolveTenantFromSubdomain
// 2. SwitchToTenantDatabase
// 3. AuthenticateUser (tenant-scoped)

// All tenant models use HasFactory + SoftDeletes
// Global scopes ensure no cross-tenant data leakage
```

### 4.3 API Response Format

```json
{
  "success": true,
  "message": "Record created successfully",
  "data": { ... },
  "meta": {
    "page": 1,
    "per_page": 25,
    "total": 500
  }
}
```

### 4.4 Dashboard Design Requirements

| Dashboard | Target User | Key Widgets |
|---|---|---|
| Management Dashboard | School Director/Owner | Student count, Fee collection %, Attendance %, Staff count, Exam results summary |
| Principal Dashboard | Principal | Today attendance, Pending approvals, Timetable conflicts, Fee defaulters |
| Teacher Dashboard | Class Teacher | My students, Homework pending, Today timetable, Assignment submissions |
| Accountant Dashboard | Fee/Accounts Staff | Daily collection, Outstanding dues, Pending approvals, Bank reconciliation status |
| Parent Dashboard | Parent/Guardian | Child attendance, Upcoming exams, Fee dues, Homework, Notices |
| Student Dashboard | Student | My courses, Homework, Exam schedule, Attendance %, LMS progress |
| Admin Dashboard | System Admin | Module health, Error logs, API usage, Tenant count |
| Prime Admin Dashboard | PrimeGurukul Staff | All tenants, MRR/ARR, Feature usage, Billing status |

### 4.5 Deployment Plan Outline

```yaml
Environment:
  Development:  Local Docker (Laravel Sail)
  Staging:      AWS EC2 t3.medium, RDS MySQL 8, Redis ElastiCache
  Production:   AWS EC2 t3.large (auto-scaling), RDS Multi-AZ, Redis cluster

CI/CD:
  Pipeline:     GitHub Actions
  Steps:
    - PHPUnit tests (must pass 100%)
    - Pest feature tests
    - Laravel Dusk browser tests
    - Build Docker image
    - Push to ECR
    - Deploy to ECS / EC2 with rolling update

Domains:
  Prime App:    admin.primegurukul.com
  Tenant App:   {school-code}.primegurukul.com
  API:          api.primegurukul.com/v1/

Database:
  global_db:    Single shared RDS instance
  tenant_db:    Per-tenant RDS or dynamically provisioned schema
  Backups:      Automated daily snapshots (30-day retention)
```

### 4.6 Notification & Event Architecture

```
Triggers → Laravel Events → Listeners → Queued Jobs
                                         ├── Email (SMTP / SES)
                                         ├── SMS (Twilio / MSG91)
                                         ├── Push (FCM / APNs)
                                         └── In-App (WebSocket / Pusher)
```

### 4.7 Report Generation Stack

| Report Type | Library | Format |
|---|---|---|
| Standard Reports | Laravel Excel (Maatwebsite) | XLSX, CSV |
| PDF Reports | DomPDF / TCPDF | PDF |
| Custom Report Cards | Custom Blade → PDF | PDF |
| Dashboard Charts | Chart.js / ApexCharts (frontend) | Interactive |
| Bulk Export | Queue-based generation → S3 download link | XLSX/PDF |

---

## 5. NEP 2020 & Compliance Requirements

| Requirement | Implementation |
|---|---|
| Holistic Progress Card (HPC) | Multi-domain assessment — cognitive, affective, psychomotor; no single rank |
| Competency-Based Assessment | Rubric-based grading with evidence portfolios |
| 5+3+3+4 Structure | Class group configuration supporting Foundational, Preparatory, Middle, Secondary stages |
| Multi-Board Support | CBSE, ICSE, IB, Cambridge, State Board templates |
| GDPR / Data Privacy | Consent management, right to be forgotten, data retention policies (Module A8) |

---

## 6. Integration Points

| Integration | Module | Type |
|---|---|---|
| Payment Gateways (Razorpay, PayU, Stripe) | J, V | REST API |
| SMS Gateway (MSG91, Twilio) | Q, A7 | REST API |
| Email (SMTP / AWS SES) | Q, A7 | SMTP / SDK |
| Biometric / RFID Attendance | F, P | Hardware API / CSV import |
| GPS Tracking (Google Maps / Device GPS) | N | REST/WebSocket |
| Tally / QuickBooks Export | K | File export (XML/CSV) |
| Push Notifications (FCM / APNs) | Q, Z | Firebase SDK |
| LMS SCORM Support | S | SCORM 1.2 / 2004 standard |
| SSO (OAuth2 / SAML) | A3, B4 | OAuth2 / SAML2 |
| OCR for Documents | R, E | Google Vision / Tesseract |

---

## 7. AI / ML Capabilities

| Capability | Module | Algorithm |
|---|---|---|
| Student Performance Prediction | U1 | Gradient Boosting / LSTM |
| Attendance Forecasting | U2 | Time-series ARIMA / Prophet |
| Fee Default Prediction | U3 | Logistic Regression / XGBoost |
| Skill Gap Analysis | U4 | Clustering + NLP |
| Transport Route Optimization | U5 | Genetic Algorithm / Google OR-Tools |
| Adaptive LMS Content | S8 | Collaborative Filtering / Content-Based |
| Timetable Generation | G5 | Constraint Satisfaction Problem (CSP) solver |
| Sentiment Analysis | U8 | NLP / BERT / Hugging Face |
| Recommendation Engine | T3 | Matrix Factorization + CBF |

---

## 8. Quick Reference — Code Map

```
Module Code Pattern:
  {Mod}.{SubMod}.{Func}.{Task}.{SubTask}
  Example: A.A1.F.A1.1.T.A1.1.1.ST.A1.1.1.1

DB Naming:
  global_db.{table}           → Prime App data
  {tenant_db}.{table}         → School App data

Route Naming:
  {module_code}.{action}      → Laravel route names
  Example: 'A1.tenants.create', 'B2.roles.index'

Permission Naming:
  {mod_code}.{sub_mod_code}.{crud}
  Example: 'A.A1.create', 'J.J3.read'
```

---

*End of Prime-AI Complete System Specification*  
*Generated from Feature_Status_v3_1.xlsx — 1112 Sub-Tasks across 27 Modules*