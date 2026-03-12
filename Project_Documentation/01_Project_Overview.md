# 01 — Project Overview

## Project Purpose

**Prime-AI** is a multi-tenant SaaS **Academic Intelligence Platform** built for Indian K-12 schools (Class 2–12). It integrates three major systems into a unified platform:

| System | Purpose |
|--------|---------|
| **ERP** | School administration — staff, students, fees, transport, vendors, complaints, scheduling |
| **LMS** | Learning Management — homework, quizzes, exams, question bank, syllabus |
| **LXP** | Learning Experience — personalized learning paths, AI recommendations, analytics, Holistic Progress Card (HPC) |

Each school operates as a completely isolated tenant with its own database, ensuring data sovereignty and regulatory compliance for Indian educational institutions.

---

## Technology Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| **Language** | PHP | 8.2+ |
| **Framework** | Laravel | 12.0 |
| **Database** | MySQL | 8.x (InnoDB, UTF8MB4) |
| **Multi-Tenancy** | stancl/tenancy | 3.9 |
| **Modules** | nwidart/laravel-modules | 12.0 |
| **Auth (API)** | Laravel Sanctum | 4.0 |
| **Auth (RBAC)** | Spatie Laravel Permission | 6.21 |
| **Media** | Spatie Laravel MediaLibrary | 11.17 |
| **Backup** | Spatie Laravel Backup | 9.3 |
| **PDF** | barryvdh/laravel-dompdf | 3.1 |
| **Excel** | maatwebsite/excel | 3.1 |
| **QR Codes** | simplesoftwareio/simple-qrcode | 4.2 |
| **Payment** | razorpay/razorpay | 2.9 |
| **Testing** | Pest | 4.1 |
| **Debug** | Laravel Telescope 5.18, Debugbar 3.16 |
| **Frontend CSS** | Bootstrap 5 + AdminLTE 4 + Tailwind CSS 3 |
| **Frontend JS** | Alpine.js 3.4 |
| **Build Tool** | Vite 7.0 |

---

## High-Level Architecture

```
                    ┌──────────────────────────────────┐
                    │         Load Balancer / DNS       │
                    └──────────────┬───────────────────┘
                                   │
              ┌────────────────────┼────────────────────┐
              │                    │                     │
    ┌─────────▼─────────┐  ┌──────▼──────┐  ┌──────────▼──────────┐
    │  Central Domain    │  │  school1.*  │  │   school2.*         │
    │  (Prime Admin)     │  │  (Tenant 1) │  │   (Tenant 2)        │
    └─────────┬─────────┘  └──────┬──────┘  └──────────┬──────────┘
              │                    │                     │
    ┌─────────▼─────────┐  ┌──────▼──────┐  ┌──────────▼──────────┐
    │  Laravel 12.0      │  │  Tenancy    │  │  Tenancy            │
    │  29 Modules        │  │  Bootstrap  │  │  Bootstrap          │
    │  Sanctum + Spatie  │  │  (DB,Cache, │  │  (DB,Cache,         │
    │                    │  │  FS,Queue)  │  │  FS,Queue)          │
    └────┬────┬─────────┘  └──────┬──────┘  └──────────┬──────────┘
         │    │                    │                     │
    ┌────▼────▼───┐        ┌──────▼──────┐      ┌──────▼──────┐
    │ global_db   │        │ tenant_uuid1│      │ tenant_uuid2│
    │ prime_db    │        │  (368 tbls) │      │  (368 tbls) │
    │ (39 tables) │        └─────────────┘      └─────────────┘
    └─────────────┘
```

### Three-Layer Database Architecture

| Layer | Database | Tables | Purpose |
|-------|----------|--------|---------|
| **Global** | `global_db` | 12 | Shared reference data: countries, states, boards, languages, menus, modules |
| **Prime** | `prime_db` | 27 | Central SaaS: tenants, plans, billing, subscriptions, central users/roles |
| **Tenant** | `tenant_{uuid}` | 368 | Per-school isolated data: students, teachers, timetable, fees, transport, etc. |

**Total: 407 unique tables across 3 database layers.**

---

## Major Components

| Component | Count | Description |
|-----------|-------|-------------|
| **Modules** | 29 (27 active + 2 pending) | Self-contained feature packages |
| **Models** | 381 | Eloquent models with relationships |
| **Controllers** | 283 | Web + API controllers |
| **Authorization Policies** | 195+ | Fine-grained RBAC policies |
| **Form Requests** | 168 | Validation classes |
| **Migrations** | 280 | Database schema definitions |
| **Services** | 12 | Business logic classes |
| **Jobs** | 9 | Async queued tasks |
| **Events/Listeners** | 3 / 2 | Event-driven side effects |
| **Blade Views** | 500+ | Server-rendered UI templates |
| **Roles** | 15 | 6 central + 9 tenant |

---

## Key Design Decisions

1. **Database-per-Tenant Isolation** — Complete data separation via Stancl Tenancy with UUID identification and domain-based routing
2. **Modular Architecture** — 29 independent modules via nwidart/laravel-modules for separation of concerns
3. **Table Prefix Convention** — 18 distinct prefixes (tt_, std_, sch_, slb_, etc.) for immediate module identification
4. **Policy-Based Authorization** — 195+ Laravel Gate policies for granular access control
5. **Soft Deletes Everywhere** — Audit trails and regulatory compliance for all school records
6. **Event-Driven Side Effects** — Complaints and notifications use async event/listener pattern
7. **AI-Powered Timetable** — FET solver with pluggable constraint system for automatic schedule generation

---

## Project Statistics Summary

| Metric | Value |
|--------|-------|
| Total PHP Files | 1,500+ |
| Total Models | 381 |
| Total Controllers | 283 |
| Total DB Tables | 407 |
| Total Migrations | 280 |
| Total Policies | 195+ |
| Tenant Route Lines | 2,628 |
| Central Route Lines | 973 |
| Composer Dependencies | 50+ packages |
| Lines in composer.lock | 12,233 |
