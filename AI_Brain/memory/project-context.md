# Project Context — Prime-AI Academic Intelligence Platform

## Application Purpose
**Academic Intelligence Platform** for Indian K-12 schools — not a traditional ERP. The goal is to enable schools to make better, data-driven decisions by providing deep insights and intelligent decision support. Each school is an isolated tenant with its own database. The platform covers:
- **ERP:** School administration, staff, students, fees, transport, vendors, complaints
- **LMS:** Homework, quizzes, exams, question bank, syllabus management
- **LXP:** Personalized learning paths, recommendations, analytics, HPC (Holistic Progress Card)
- **Intelligence Layer:** Data insights, AI-driven recommendations, decision support across all modules

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

### Layer 3: Tenant DB (`tenant_db`) — 370 tables
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

> **Schema Reference (CANONICAL — v4 DEV files for all AI work):**
> - `{DEV_GLOBAL_DDL}` — global_db development schema
> - `{DEV_PRIME_DDL}` — prime_db development schema
> - `{DEV_TENANT_DDL}` — tenant_db development schema (includes global_db copies for dev)
> - `{DEV_MODULE_DDL_DIR}/{MODULE_NAME}_DDL*.sql` — per-module tenant DDL files
>
> Production v3 files (`{GLOBAL_DDL}`, `{PRIME_DDL}`, `{TENANT_DDL}`) live in `{DB_REPO}` — used by Laravel, not for AI analysis.
> **NEVER use files from `0-DDL_Masters_Old/`, `2-DDL_Tenant_Old/`, or any `*_Old*` subfolder.**

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

## Key Statistics (re-verified 2026-06-21 against `prime_ai` branch `Brijesh`)
| Metric | Count |
|--------|-------|
| Modules | 45 (5 central + 40 tenant) |
| Total Models | 806 |
| Total Controllers | 747 |
| Total Services | 318 |
| Total FormRequests | 451 |
| Total Blade Views | 3,764 |
| Tenant DB Tables | 370+ |
| Central DB Tables | ~39 (global + prime) |
| Authorization Policies | ~230 |
| Tenant Migrations | 608 files in `database/migrations/tenant/` |
| Central Migrations | 5 files in `database/migrations/` + 37 in `Modules/Prime/database/migrations/` |
| Module Route Lines | 8,315 across all `routes/*.php` in module dirs |
| Module-level Test Files | 80 |
| **Overall platform completion** | **~31%** of RBS (1112 sub-tasks); stats re-verified 2026-06-21 |
| **Full project docs** | `{PROJECT_DOCS}/` (12 files — overview, guides, reference) |

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
