# Project Context — Prime-AI Academic Intelligence Platform

## Application Purpose
SaaS platform for managing Indian K-12 schools (Class 2-12). Each school is an isolated tenant with its own database. The platform covers:
- **ERP:** School administration, staff, students, fees, transport, vendors, complaints
- **LMS:** Homework, quizzes, exams, question bank, syllabus management
- **LXP:** Personalized learning paths, recommendations, analytics, HPC (Holistic Progress Card)

## Tenancy Strategy
- **Package:** stancl/tenancy v3.9
- **Model:** Separate database per tenant (database-per-tenant isolation)
- **ID Generation:** UUID (`Stancl\Tenancy\UUIDGenerator`)
- **Identification:** Domain-based routing
- **Bootstrappers:** Database, Cache, Filesystem, Queue

## Database Architecture (3-Layer)

### Layer 1: Global DB (`global_db`) — 12 tables
Shared reference data across all tenants:
- `glb_countries`, `glb_states`, `glb_cities`, `glb_districts`
- `glb_boards` (educational boards: CBSE, ICSE, etc.)
- `glb_languages`, `glb_translations`
- `glb_menus`, `glb_modules`, `glb_menu_model_jnt`
- `glb_academic_sessions`

### Layer 2: Prime DB (`prime_db`) — 27 tables
Central SaaS management:
- **Tenants:** `prm_tenant`, `prm_tenant_domains`, `prm_tenant_groups`
- **Plans:** `prm_plans`, `prm_tenant_plan_jnt`, `prm_tenant_plan_module_jnt`, `prm_tenant_plan_rates`
- **Billing:** `bil_tenant_invoices`, `bil_tenant_invoicing_payments`, `bil_tenant_invoicing_audit_logs`
- **System:** `sys_users`, `sys_roles`, `sys_permissions`, `sys_settings`, `sys_media`, `sys_activity_logs`

### Layer 3: Tenant DB (`tenant_db`) — 368 tables
Per-school isolated data organized by prefix (see consolidated DDL for full list):
- `sys_*` — Tenant-level RBAC, settings, media
- `sch_*` — School setup, organizations
- `tt_*` — Timetable generation system
- `std_*` — Student management
- `slb_*` — Syllabus & curriculum
- `qns_*` — Question bank
- `tpt_*` — Transport management
- `ntf_*` — Notifications
- `vnd_*` — Vendor management
- `cmp_*` — Complaints
- `rec_*` — Recommendations
- `bok_*` — Books
- `hpc_*` — Holistic Progress Card
- `fin_*` — Finance/Fees
- `exm_*` — Examinations
- `quz_*` — Quiz/Assessment
- And more (refer to consolidated DDL for complete list)

> **Schema Reference (CANONICAL — v2 files only):**
> - `/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/1-master_dbs/1-DDLs/global_db_v2.sql`
> - `/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/1-master_dbs/1-DDLs/prime_db_v2.sql`
> - `/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/1-master_dbs/1-DDLs/tenant_db_v2.sql`
> **NEVER use old DDL files in subfolders (`2-Prime_Modules/`, `2-Tenant_Modules/`, etc.)**

## External Services
- **Payment Gateway:** Razorpay (`razorpay/razorpay` v2.9)
- **Email:** Configurable (SMTP/log for dev)
- **Storage:** Local filesystem with tenant-specific paths (`storage/tenant_{id}/`)
- **Queue:** Database driver (configurable to Redis)
- **Cache:** Database driver (configurable to Redis)
- **PDF Generation:** DomPDF (`barryvdh/laravel-dompdf`)
- **Excel Import/Export:** Maatwebsite Excel
- **QR Codes:** SimpleSoftwareIO QR Code

## External Services
- **Payment Gateway:** Razorpay (`razorpay/razorpay` v2.9)
- **Email:** Configurable (SMTP/SES/Mailgun/Log for dev). Mailable classes: InvoiceMail, VendorInvoiceMail, LoginMail
- **Storage:** Local filesystem with tenant-specific paths (`storage/tenant_{id}/`). S3 configured but not primary.
- **Queue:** Database driver (configurable to Redis). Queued jobs for email, reports, timetable
- **Cache:** Database driver (configurable to Redis). NOTE: Zero application-level caching currently — critical issue
- **PDF Generation:** DomPDF (`barryvdh/laravel-dompdf` v3.1) — invoices, receipts, reports, HPC
- **Excel Import/Export:** Maatwebsite Excel (`maatwebsite/excel` v3.1) — chunk 1000, lessons/allocations/fees
- **QR Codes:** SimpleSoftwareIO QR Code v4.2 — driver attendance, student boarding, student IDs
- **Media Library:** Spatie MediaLibrary v11.17 — profile photos, documents, vehicle photos, evidence
- **Backup:** Spatie Laravel Backup v9.3 — full DB + file backups with configurable destinations
- **Debug:** Laravel Telescope 5.18 + Debugbar 3.16

## Frontend Stack
- Bootstrap 5 + AdminLTE 4 + Tailwind CSS 3
- Alpine.js 3.4
- Vite 7.0 build tool

## Key Statistics
| Metric | Count |
|--------|-------|
| Modules | 29 (27 active + 2 pending) |
| Total Models | 381 |
| Total Controllers | 283 |
| Total Services | 12 |
| Total Jobs | 9 |
| Tenant DB Tables | 368 |
| Central DB Tables | 39 (global + prime) |
| Total DB Tables | 407 |
| Authorization Policies | 195+ |
| Form Requests | 168 |
| Tenant Migrations | 216 files |
| Central Migrations | 6 files |
| Blade Views | 500+ |
| Central Roles | 6 |
| Tenant Roles | 9 |
| Tenant Route Lines | 2,628 |
| Central Route Lines | 973 |

## Key Business Workflows
1. **Tenant Onboarding:** TenantController → UUID creation → domain setup → DB provisioning → migrations → CreateRootUser job → plan assignment
2. **AI Timetable Generation:** Activity scoring → room availability → sub-activity generation → FET solver (50K iterations, 25s timeout) → atomic persistence → approval workflow → publish
3. **Student Admission:** StudentController → user creation → academic session enrollment → guardian linking → profile completion → fee assignment → transport allocation
4. **Fee Payment:** Fee structure → student assignment → invoice generation → Razorpay checkout → webhook callback → signature verification → receipt creation
5. **Complaint AI:** ComplaintSaved event → ProcessComplaintAIInsights (queued) → sentiment + risk + category scoring → cmp_ai_insights record
6. **Notification Dispatch:** SystemNotificationTriggered event → ProcessSystemNotification (queued) → template render → channel dispatch (Email/In-App; SMS/Push stubbed)

## Authorization Architecture
- **Pattern:** Gate::before() → Super Admin bypass → Gate::policy() → Policies → Spatie role checks
- **Permission format:** `module.feature.action` (e.g., `prime.tenant.create`, `tenant.timetable.generate`)
- **Central roles:** Super Admin, Manager, Accounting, Invoicing, Student, Parent
- **Tenant roles:** Super Admin, Principal, Vice Principal, Teacher, Staff, Accountant, Librarian, Parent, Student
- **RBAC tables:** sys_users ↔ sys_model_has_roles_jnt ↔ sys_roles ↔ sys_role_has_permissions_jnt ↔ sys_permissions
