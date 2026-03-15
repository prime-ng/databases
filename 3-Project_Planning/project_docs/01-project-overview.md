# Prime-AI — Project Overview

## Project Identity

- **Name:** Prime-AI ERP + LMS + LXP
- **Purpose:** Multi-Tenant SaaS Academic Intelligence Platform for Indian K-12 Schools
- **Tech:** PHP 8.2+ / Laravel 12.0 / MySQL 8.x / stancl/tenancy v3.9 / nwidart/laravel-modules v12.0

## Two Sides of the Application

- **PRIME side** = Application owner/super-admin (one instance, central). Manages tenants, billing, global config.
- **TENANT side** = Each school (separate database + separate subdomain). Runs academics, fees, HR, transport, LMS.
- **Multi-tenancy:** stancl/tenancy creates a new DB and domain per school automatically. `InitializeTenancyByDomain` middleware switches DB context on every request.

## 3-Layer Database Architecture

| Layer | Database | Tables | Prefix | Purpose |
|-------|----------|--------|--------|---------|
| Global | `global_db` | ~12 | `glb_*` | Shared reference data: countries, states, boards, languages, modules |
| Prime | `prime_db` | ~27 | `prm_*`, `bil_*`, `sys_*` | SaaS management: tenants, plans, billing, central users/roles |
| Tenant | `tenant_db` | ~368 | `tt_*`, `std_*`, `sch_*`, `fin_*`, etc. | Per-school everything: students, teachers, timetable, fees, etc. |

## Table Prefix Convention (full list)

```
sys_  -> System config             glb_  -> Global master data
prm_  -> Prime admin tables        bil_  -> Billing tables
sch_  -> School setup              tt_   -> Timetable
std_  -> Student data              slb_  -> Syllabus
qns_  -> Questions / Question bank rec_  -> Recommendations
bok_  -> Books / SyllabusBooks     cmp_  -> Complaints
ntf_  -> Notifications             tpt_  -> Transport
vnd_  -> Vendor                    hpc_  -> Holistic Progress Card
fin_  -> Fees / Finance            exm_  -> Exams
quz_  -> Quiz                     lib_  -> Library
beh_  -> Behaviour (reserved)      hos_  -> Hostel (reserved)
mes_  -> Mess (reserved)           acc_  -> Accounting (reserved)
_jnt  -> Junction/bridge tables (suffix)
_json -> JSON column (suffix)
```

## 27 Modules — Full List

| Module | Side | Status | Table Prefix | Controllers | Models |
|--------|------|--------|--------------|-------------|--------|
| Prime | Central | 80% | prm_* | 22 | 27 |
| GlobalMaster | Central | 82% | glb_* | 15 | 12 |
| SystemConfig | Central | 75% | sys_* | 3 | 3 |
| Billing | Central | 70% | bil_* | 6 | 6 |
| Documentation | Central | 100% | doc_* | 3 | 2 |
| SchoolSetup | Tenant | 80% | sch_* | 34 | 42 |
| SmartTimetable | Tenant | 60% | tt_* | 27 | 86 |
| Transport | Tenant | 82% | tpt_* | 31 | 36 |
| StudentProfile | Tenant | 80% | std_* | 5 | 14 |
| Syllabus | Tenant | 78% | slb_* | 15 | 22 |
| SyllabusBooks | Tenant | 65% | bok_* | 4 | 6 |
| QuestionBank | Tenant | 75% | qns_* | 7 | 17 |
| Notification | Tenant | 55% | ntf_* | 12 | 14 |
| Complaint | Tenant | 70% | cmp_* | 8 | 6 |
| Vendor | Tenant | 60% | vnd_* | 7 | 8 |
| Payment | Tenant | 45% | pay_* | 4 | 5 |
| Dashboard | Tenant | 100% | - | 1 | 0 |
| Scheduler | Tenant | 100% | - | 1 | 2 |
| Hpc | Tenant | 68% | hpc_* | 15 | 26 |
| LmsExam | Tenant | 65% | exm_* | 11 | 11 |
| LmsQuiz | Tenant | 72% | quz_* | 5 | 6 |
| LmsHomework | Tenant | 60% | - | 5 | 5 |
| LmsQuests | Tenant | 68% | - | 4 | 4 |
| StudentFee | Tenant | 60% | fin_* | 15 | 23 |
| Recommendation | Tenant | 65% | rec_* | 10 | 11 |
| StudentPortal | Tenant | 25% | - | 3 | 0 |
| Library | Tenant | 45% | lib_* | 26 | 35 |

## Key Paths

| Item | Path |
|------|------|
| Application Code | `/Users/bkwork/Herd/prime_ai_shailesh/` |
| AI Brain | `/Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/` |
| Central Migrations | `database/migrations/` |
| Tenant Migrations | `database/migrations/tenant/` (278 files) |
| Modules | `Modules/{ModuleName}/` |
| Policies | `app/Policies/` (195+ authorization policies) |
| Helpers | `app/Helpers/` (helpers.php, PermissionHelper.php, activityLog.php) |
| Shared Components | `resources/views/components/backend/`, `prime/`, `frontend/` |

## Critical Rules

1. **NEVER mix central and tenant scoped code.** Always know which context you're in.
2. **Tenant migrations go in `database/migrations/tenant/`** — NEVER inside module folders.
3. **Prime routes in `routes/web.php`** — Tenant routes in `routes/tenant.php`.
4. **Always use table prefix convention** when creating tables.
5. **Every table must have:** `id`, `is_active`, `created_by`, `created_at`, `updated_at`, `deleted_at`.
