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

### Layer 3: Tenant DB (`tenant_db`) — 159 tables
Per-school isolated data organized by prefix:
- `sys_*` (11) — Tenant-level RBAC, settings, media
- `sch_*` (7) — School setup, organizations
- `tt_*` (41) — Timetable generation system
- `std_*` (14) — Student management
- `slb_*` (16) — Syllabus & curriculum
- `qns_*` (12) — Question bank
- `tpt_*` (28) — Transport management
- `ntf_*` (8) — Notifications
- `vnd_*` (7) — Vendor management
- `cmp_*` (6) — Complaints
- `rec_*` (11) — Recommendations
- `bok_*` (4) — Books
- `hpc_*` (12) — Holistic Progress Card
- `fin_*` — Finance/Fees (pending)

## External Services
- **Payment Gateway:** Razorpay (`razorpay/razorpay` v2.9)
- **Email:** Configurable (SMTP/log for dev)
- **Storage:** Local filesystem with tenant-specific paths (`storage/tenant_{id}/`)
- **Queue:** Database driver (configurable to Redis)
- **Cache:** Database driver (configurable to Redis)
- **PDF Generation:** DomPDF (`barryvdh/laravel-dompdf`)
- **Excel Import/Export:** Maatwebsite Excel
- **QR Codes:** SimpleSoftwareIO QR Code

## Key Statistics
| Metric | Count |
|--------|-------|
| Modules | 29 |
| Total Models | ~400+ |
| Total Controllers | 273+ |
| Tenant DB Tables | 159 |
| Central DB Tables | 39 (global + prime) |
| Total DB Tables | 198 |
| Authorization Policies | 195+ |
| Tenant Migrations | 216 files |
| Central Migrations | 6 files |
